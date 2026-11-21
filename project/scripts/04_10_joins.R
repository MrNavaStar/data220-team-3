# scripts/04_10_joins.R -- M2 Task 2: aggregate each table to year and join.
# Reads:  data/processed/{severity,locations,temporal,injuries}.csv
# Writes: output/yearly_summary.csv     (one row per year, all four tables joined)
#
# DECISION: aggregate every child table to the year grain BEFORE joining severity.
# If we join on year without aggregating first, a temporal table with ~18 k rows
# multiplies into ~18 k severity rows, inflating every count.  Aggregating to one
# row per year first guarantees a clean many-to-one join on year.
source("config.R")
source("R/load_functions.R")
log_msg("04_10_joins: start")

severity  <- read.csv("data/processed/severity.csv")
locations <- read.csv("data/processed/locations.csv")
temporal  <- read.csv("data/processed/temporal.csv")
injuries  <- read.csv("data/processed/injuries.csv")

# ---- locations: total collisions per year (all location types summed) --------
locations_by_year <- locations |>
  group_by(year) |>
  summarise(total_locations_collisions = sum(collision_count, na.rm = TRUE),
            distinct_location_types   = n_distinct(location_type),
            .groups = "drop")
check_key(locations_by_year, "year", "locations_by_year")

# ---- temporal: count of rows per year per classification ---------------------
# (each row in the temporal table = 1 collision, so count rows = total collisions)
temporal_by_year <- temporal |>
  group_by(year, collision_classification) |>
  summarise(collisions = n(), .groups = "drop") |>
  pivot_wider(
    names_from = collision_classification,
    values_from = collisions,
    values_fill = 0
  ) |>
  mutate(total_temporal_collisions = rowSums(pick(where(is.numeric)))) |>
  select(-any_of(c("Fatal", "Minor", "Pdo", "Serious", "Major")))
check_key(temporal_by_year, "year", "temporal_by_year")

# ---- injuries: count people (injured or killed) per year, by severity -------
# Each row in injuries table = one person; count rows = total people.
injuries_by_year <- injuries |>
  group_by(year, injury_severity) |>
  summarise(people = n(), .groups = "drop") |>
  pivot_wider(
    names_from = injury_severity,
    values_from = people,
    values_fill = 0
  ) |>
  mutate(total_injuries_people = rowSums(pick(where(is.numeric)))) |>
  select(-any_of(c("Fatal", "Minor", "Serious", "Major")))
check_key(injuries_by_year, "year", "injuries_by_year")

# ---- join everything on year ------------------------------------------------
yearly <- severity |>
  safe_left_join(locations_by_year,  by = "year", name = "severity + locations") |>
  safe_left_join(temporal_by_year,   by = "year", name = "severity + temporal") |>
  safe_left_join(injuries_by_year,   by = "year", name = "severity + injuries")

# Verify no rows were lost
stopifnot(nrow(yearly) == nrow(severity))
check_key(yearly, "year", "yearly_summary")

save_csv(yearly, "output/yearly_summary.csv")

# Print the 2019-2023 slice for quick inspection
out <- yearly |> filter(year %in% 2019:2023)
cat("--- 2019-2023 yearly summary (", nrow(out), "rows) ---\n")
write.csv(out, "output/yearly_summary_2019_2023.csv", row.names = FALSE)
cat("(see output/yearly_summary_2019_2023.csv)\n\n")

log_msg("04_10_joins: done -- ", nrow(yearly), " rows joined on year")
