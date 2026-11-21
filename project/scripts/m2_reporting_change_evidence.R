# scripts/m2_reporting_change_evidence.R -- M2 Task 4: descriptive tables behind
# reports/M2_reporting_change_notes.md. Unnumbered, so run_all.R does not run it.
# From project/:  source("scripts/m2_reporting_change_evidence.R")
# Reads:  data/sample/{severity,temporal,injuries} (committed API snapshot)
# Writes: output/m2_reporting_monthly_collisions.csv
#         output/m2_reporting_annual_casualties.csv
#         output/m2_reporting_minor_injuries_by_mode.csv
# DESCRIPTIVE ONLY: these tables show WHEN and WHERE recorded counts changed;
# they do not establish why.
source("config.R")
source("R/load_functions.R")
log_msg("m2_reporting_change_evidence: start")

temporal <- read_json_records(file.path("data/sample", "temporal"))
injuries <- read_json_records(file.path("data/sample", "injuries"))
severity <- read_json_records(file.path("data/sample", "severity"))

# 1. Monthly collisions by classification, 2021-2023 (around September 2022).
temporal$collisions <- as.numeric(temporal$collisions)
temporal$class <- ifelse(temporal$collision_classification %in% c("Serious", "Major"),
                         "Serious/Major", temporal$collision_classification)
monthly <- temporal |>
  filter(collision_report_year %in% c("2021", "2022", "2023")) |>
  group_by(year = collision_report_year, month = collision_report_month_name, class) |>
  summarise(collisions = sum(collisions), .groups = "drop") |>
  pivot_wider(names_from = class, values_from = collisions, values_fill = 0) |>
  mutate(month_num = match(month, toupper(month.name))) |>
  arrange(year, month_num) |>
  select(year, month_num, month, Fatal, `Serious/Major`, Minor, PDO)
save_csv(monthly, "output/m2_reporting_monthly_collisions.csv")
print(as.data.frame(monthly), row.names = FALSE)

# 2. Annual people injured/killed and collision tiers (severity source), 2019-2023.
num <- function(x) as.numeric(x)
annual <- severity |>
  filter(num(year) %in% 2019:2023) |>
  transmute(year = num(year), total_collisions = num(total_collisions),
            pdo_collisions = num(property_damage_only_pdo),
            minor_injury_collisions = num(minor_injury_collisions),
            serious_injury_collisions = num(serious_injury_collisions),
            fatal_collisions = num(fatal_collisions),
            fatalities = num(total_fatalities),
            serious_injuries = num(total_serious_injuries),
            minor_injuries = num(total_minor_injuries),
            fatalities_injuries = num(total_fatalities_injuries)) |>
  arrange(year)
save_csv(annual, "output/m2_reporting_annual_casualties.csv")
print(as.data.frame(annual), row.names = FALSE)

# 3. Minor injuries (people) by road-user mode and year.
injuries$people <- as.numeric(injuries$sum_of_injuries_and_fatalities)
by_mode <- injuries |>
  filter(injury_severity == "MINOR") |>
  group_by(injury_mode, year = collision_report_year) |>
  summarise(people = sum(people), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = people, values_fill = 0) |>
  arrange(injury_mode)
save_csv(by_mode, "output/m2_reporting_minor_injuries_by_mode.csv")
print(as.data.frame(by_mode), row.names = FALSE)

log_msg("m2_reporting_change_evidence: done")
