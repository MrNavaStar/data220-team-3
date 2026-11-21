# scripts/04_checks.R -- M2 Task 3: cross-source reconciliation, 2019-2023.
# Reads:  data/interim/{severity,temporal,injuries}_raw.csv  (from 01_extract.R)
#         -- the raw extracts, because 03_transform.R drops the count columns.
# Writes: output/m2_cross_source_checks.csv  (one row per year x check)
# Stops:  if any 2019-2023 total disagrees, a year is missing, a count is
#         missing/non-numeric, or a category label is not one we have mapped.
# Runs on its own after 01_extract.R, and automatically inside run_all.R.
#
# WHICH METRICS ARE COMPARED (verified against the API data and field names):
#   temporal.collisions  = number of COLLISION EVENTS in each year/time/class cell
#     sum by year                         == severity.total_collisions
#     class Fatal                         == severity.fatal_collisions
#     class Serious (2019) / Major (2020+) == severity.serious_injury_collisions
#     class Minor                         == severity.minor_injury_collisions
#     class PDO                           == severity.property_damage_only_pdo
#   injuries.sum_of_injuries_and_fatalities = number of PEOPLE injured or killed
#     sum by year                         == severity.total_fatalities_injuries
#     severity FATAL                      == severity.total_fatalities
#     severity SERIOUS / MAJOR            == severity.total_serious_injuries
#     severity MINOR                      == severity.total_minor_injuries
#   Collision events and injured people are different units: never compare
#   temporal collisions with injury counts.
#   "Serious" and "Major" are treated as the same tier ONLY here, because both
#   reconcile exactly to severity.serious_injury_* in their years; the label
#   change is documented in reports/M2_reporting_change_notes.md.
source("config.R")
source("R/load_functions.R")
log_msg("04_checks: start")

YEARS <- 2019:2023

read_interim <- function(name, needed) {
  path <- paste0("data/interim/", name, "_raw.csv")
  if (!file.exists(path)) stop("04_checks: ", path, " not found -- run scripts/01_extract.R first")
  df <- read_raw_csv(path)
  check_columns(df, needed, paste0("04_checks ", name))
  df
}
as_count <- function(x, label) {
  val <- suppressWarnings(as.numeric(x))
  if (anyNA(val)) stop("04_checks: missing/non-numeric value(s) in ", label)
  val
}

severity <- read_interim("severity", c(
  "year", "total_collisions", "property_damage_only_pdo", "fatal_collisions",
  "serious_injury_collisions", "minor_injury_collisions",
  "total_fatal_injury_collisions", "total_fatalities", "total_serious_injuries",
  "total_minor_injuries", "total_serious_minor_injuries", "total_fatalities_injuries"))
temporal <- read_interim("temporal", c("collision_report_year", "collision_classification",
                                       "collisions"))
injuries <- read_interim("injuries", c("collision_report_year", "injury_severity",
                                       "sum_of_injuries_and_fatalities"))

for (col in setdiff(names(severity), "source_file")) {
  severity[[col]] <- as_count(severity[[col]], paste("severity", col))
}
temporal$year <- as_count(temporal$collision_report_year, "temporal year")
temporal$collisions <- as_count(temporal$collisions, "temporal collisions")
injuries$year <- as_count(injuries$collision_report_year, "injuries year")
injuries$people <- as_count(injuries$sum_of_injuries_and_fatalities, "injuries counts")

if (anyDuplicated(severity$year)) stop("04_checks: severity has repeated years")
for (y in YEARS) {
  if (!y %in% severity$year || !y %in% temporal$year || !y %in% injuries$year) {
    stop("04_checks: year ", y, " is missing from one or more sources")
  }
}

# Map published labels to tiers; stop on any label we have not verified.
tier_of <- function(labels, map, label) {
  key <- toupper(trimws(labels))
  unknown <- setdiff(unique(key), names(map))
  if (length(unknown)) stop("04_checks: unmapped ", label, " label(s): ",
                            paste(unknown, collapse = ", "),
                            ". Check the City's definitions before adding them.")
  unname(map[key])
}
temporal$tier <- tier_of(temporal$collision_classification,
                         c(FATAL = "fatal", SERIOUS = "serious", MAJOR = "serious",
                           MINOR = "minor", PDO = "pdo"), "temporal collision_classification")
injuries$tier <- tier_of(injuries$injury_severity,
                         c(FATAL = "fatal", SERIOUS = "serious", MAJOR = "serious",
                           MINOR = "minor"), "injuries injury_severity")

# One comparison: a source sum per year against a severity column.
compare <- function(check, unit, df, value, severity_col, tiers = NULL) {
  out <- data.frame(year = YEARS, check = check, unit = unit,
                    severity_column = severity_col)
  out$source_total <- sapply(YEARS, function(y) {
    keep <- df$year == y
    if (!is.null(tiers)) keep <- keep & df$tier %in% tiers
    sum(df[[value]][keep])
  })
  out$severity_total <- sapply(YEARS, function(y) severity[[severity_col]][severity$year == y])
  out
}

result <- rbind(
  # Primary annual checks (professor feedback Task 3)
  compare("temporal collisions vs severity", "collisions", temporal, "collisions",
          "total_collisions"),
  compare("injuries people vs severity", "people", injuries, "people",
          "total_fatalities_injuries"),
  # Component checks: confirm we are comparing the same measures
  compare("temporal Fatal", "collisions", temporal, "collisions", "fatal_collisions", "fatal"),
  compare("temporal Serious/Major", "collisions", temporal, "collisions",
          "serious_injury_collisions", "serious"),
  compare("temporal Minor", "collisions", temporal, "collisions", "minor_injury_collisions", "minor"),
  compare("temporal PDO", "collisions", temporal, "collisions", "property_damage_only_pdo", "pdo"),
  compare("injuries FATAL", "people", injuries, "people", "total_fatalities", "fatal"),
  compare("injuries SERIOUS/MAJOR", "people", injuries, "people", "total_serious_injuries", "serious"),
  compare("injuries MINOR", "people", injuries, "people", "total_minor_injuries", "minor")
)

# Internal consistency of the severity table itself.
sev <- severity[match(YEARS, severity$year), ]
result <- rbind(result,
  data.frame(year = YEARS, check = "severity PDO + fatal/injury collisions", unit = "collisions",
             severity_column = "total_collisions",
             source_total = sev$property_damage_only_pdo + sev$total_fatal_injury_collisions,
             severity_total = sev$total_collisions),
  data.frame(year = YEARS, check = "severity fatalities + injuries", unit = "people",
             severity_column = "total_fatalities_injuries",
             source_total = sev$total_fatalities + sev$total_serious_minor_injuries,
             severity_total = sev$total_fatalities_injuries))

result$difference <- result$source_total - result$severity_total
result$match <- result$difference == 0
save_csv(result, "output/m2_cross_source_checks.csv")

pc <- result[result$check == "temporal collisions vs severity", ]
pp <- result[result$check == "injuries people vs severity", ]
print(data.frame(year = YEARS,
                 temporal_collisions = pc$source_total, severity_collisions = pc$severity_total,
                 collisions_match = pc$match,
                 injuries_people = pp$source_total, severity_people = pp$severity_total,
                 people_match = pp$match), row.names = FALSE)

bad <- result[!result$match, ]
if (nrow(bad)) {
  print(bad[, c("year", "check", "source_total", "severity_total", "difference")],
        row.names = FALSE)
  stop("04_checks: cross-source totals DISAGREE in ", nrow(bad), " comparison(s) ",
       "(years ", paste(unique(bad$year), collapse = ", "), "). ",
       "See output/m2_cross_source_checks.csv")
}
log_msg("04_checks: all ", nrow(result), " comparisons match for ",
        min(YEARS), "-", max(YEARS),
        " (annual collisions and casualties reconcile with severity)")
