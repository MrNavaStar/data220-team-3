# scripts/04_validate.R -- checks that STOP if something is wrong. If this script
# reaches its last line, every check passed.  Writes: output/quality_report.csv
source("config.R")
source("R/load_functions.R")
log_msg("04_validate: start")

severity  <- read.csv("data/processed/severity.csv")
locations <- read.csv("data/processed/locations.csv")
temporal  <- read.csv("data/processed/temporal.csv")
injuries  <- read.csv("data/processed/injuries.csv")

# Key checks
check_key(severity,   TABLES$severity$key,   "severity")
check_key(locations,  TABLES$locations$key,  "locations")
check_key(temporal,   TABLES$temporal$key,   "temporal")
check_key(injuries,   TABLES$injuries$key,   "injuries")

# Range checks
check_range(severity$year, 2000, 2030, "severity year")
check_range(locations$year, 2000, 2030, "locations year")
check_range(temporal$year, 2000, 2030, "temporal year")
check_range(injuries$year, 2000, 2030, "injuries year")
check_range(locations$collision_count, 0, 100000, "collision_count")
check_range(temporal$hour, 0, 24, "hour")

# Allowed-value checks
# M2 Task 5: location_type after title-case standardization.
# Midblock, Mid Avenue, Mid Street, Intersection, South Of Intersection.
check_allowed(locations$location_type,
              c("Intersection", "Midblock", "Mid Street", "Mid Avenue",
                "South Of Intersection"), "location_type")

# M2 Task 7: season includes Fall (was missing from earlier checks).
check_allowed(temporal$season, c("Winter", "Spring", "Summer", "Fall"), "season")

# M2 Task 6: collision_classification includes Major (2020+) as alias for Serious.
check_allowed(temporal$collision_classification,
              c("Minor", "Pdo", "Serious", "Fatal", "Major"), "collision_classification")

# M2 Task 6: injury_severity includes Major (2020-2021) as alias for Serious.
check_allowed(injuries$injury_severity, c("Fatal", "Serious", "Minor", "Major"),
              "injury_severity")

save_quality_report(
  report_row("03_transform", "severity",  14, nrow(severity),  "one row per year"),
  report_row("03_transform", "locations", nrow(locations), nrow(locations), "year + type + rank + desc"),
  report_row("03_transform", "temporal",  nrow(temporal),  nrow(temporal),  "7-field key (hour_group removed per M2 Task 7); source_file, collisions, hour_group dropped"),
  report_row("03_transform", "injuries",  nrow(injuries),  nrow(injuries),  "sum_of_injuries_and_fatalities dropped")
)

log_msg("04_validate: all checks passed")
