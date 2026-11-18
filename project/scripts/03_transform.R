# scripts/03_transform.R -- rename columns, convert types, drop unwanted columns.
# Reads: data/interim/*_clean.csv      Writes: data/processed/*.csv
source("config.R")
source("R/load_functions.R")
log_msg("03_transform: start")

# =============================== severity ===========================================
severity <- read_raw_csv("data/interim/severity_raw.csv") |>
  clean_names() |>
  mutate(across(
    c(year, population, private_passenger_vehicles, private_motorcycles,
      bicycle_collisions, motorcycle_collisions, pedestrian_collisions,
      total_collisions, collisions_per_1_000_population,
      property_damage_only_pdo_collisions, injuries_fatalities_per_1_000_population,
      injuries_per_1_000_population, fatalities_per_1_000_population,
      fatality_bicyclist, fatality_motorcyclist, fatality_pedestrian,
      fatality_vehicle_driver, fatality_vehicle_passenger,
      total_fatalities, serious_injuries_bicyclist, minor_injuries_bicyclist,
      serious_injury_motorcyclist, minor_injuries_motorcyclist,
      serious_injuries_pedestrian, minor_injuries_pedestrian,
      total_serious_injuries, total_minor_injuries,
      total_serious_minor_injuries, total_fatalities_injuries,
      fatalities_intersection, fatalities_intersection_percent,
      fatalities_midblock, fatalities_midblock_percent,
      injuries_intersection, injuries_intersection_percent,
      injuries_midblock, injuries_midblock_percent,
      fatal_collisions, serious_injury_collisions, minor_injury_collisions,
      total_serious_minor_injury_collisions, total_fatal_injury_collisions),
    ~ to_number(.)
  ))

check_key(severity, TABLES$severity$key, "severity")
save_csv(severity, "data/processed/severity.csv")

# =============================== locations ==========================================
locations <- read_raw_csv("data/interim/locations_raw.csv") |>
  clean_names() |>
  mutate(rank = to_number(rank), collision_count = to_number(collision_count)) |>
  mutate(
    year = to_number(year),
    location_type = standardize_text(location_type, case = "title"),
    location_description = standardize_text(location_description, case = "title")
  ) |>
  select(year, location_type, rank, location_description, collision_count)

check_key(locations, TABLES$locations$key, "locations")
save_csv(locations, "data/processed/locations.csv")

# =============================== temporal ===========================================
# Drop metadata columns added by JSON reading (source_file) and the raw
# collisions count that duplicates the analysis grain.
temporal <- read_raw_csv("data/interim/temporal_clean.csv") |>
  select(-source_file, -collisions)

check_key(temporal, TABLES$temporal$key, "temporal")
save_csv(temporal, "data/processed/temporal.csv")

# =============================== injuries ===========================================
# Drop the sum column -- each row already identifies the breakdown by severity,
# age group, gender, etc.
injuries <- read_raw_csv("data/interim/injuries_clean.csv") |>
  select(-sum_of_injuries_and_fatalities)

check_key(injuries, TABLES$injuries$key, "injuries")
save_csv(injuries, "data/processed/injuries.csv")

log_msg("03_transform: done")
