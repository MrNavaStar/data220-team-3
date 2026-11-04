# scripts/02_clean.R -- P6: your first cleaning steps, one decision at a time.
# Reads: data/interim/<source>_raw.csv      Writes: data/interim/<source>_clean.csv
# Lab 8 continues from here (more cleaning, joins, checks, the database, queries).
source("config.R")
source("R/load_functions.R")
log_msg("02_clean: start")

# =============================================================================
# TASK P6 -- clean ONE table (more if you have time), step by step
# -----------------------------------------------------------------------------
# For every step, write the three lines, then the code (see weather/scripts/02_clean.R):
#   - FOUND:    what an inspect function showed you          (the problem)
#   - DECISION: which toolkit function you use, and WHY it is the right fix
#   - CHECK:    how you know it worked (check_key(), find_text_variants() again, ...)
# End with check_key() on the key you planned in config.R, and save_csv().
# =============================================================================
# Example step (coffee-cart sales):
#   sales <- read_raw_csv("data/interim/sales_raw.csv") |> clean_names()
#   # FOUND:    find_text_variants(sales, "item") shows "Latte", "latte " and "LATTE".
#   # DECISION: standardize_text(case = "title"), because only spaces and capitals differ.
#   sales <- mutate(sales, item = standardize_text(item, case = "title"))
#   # CHECK:    find_text_variants(sales, "item") now finds nothing.

# =============================== injuries =============================================
# FOUND:    profile_raw_file(SOURCES$injuries$file) shows source column names contain
#           spaces and punctuation; the table plan uses simple key names.
# DECISION: clean_names() makes the source headers usable, then rename_columns() aligns
#           the key columns with TABLES$injuries$key.
injuries <- read_raw_csv("data/interim/injuries_raw.csv") |>
  clean_names() |>
  rename_columns(c(
    collision_report_year = "year",
    injury_age_group = "age_group",
    injury_gender = "gender",
    traffic_control_name = "traffic_control"
  ))
# CHECK:    every planned key column is present after the names are standardized.
stopifnot(all(TABLES$injuries$key %in% names(injuries)))

# FOUND:    profile_raw_file() identifies year and the injury/fatality total as numbers,
#           but read_raw_csv() deliberately keeps source values as text.
# DECISION: to_number() converts only those measured fields, preserving categories as text.
injuries <- injuries |>
  mutate(
    year = to_number(year),
    sum_of_injuries_and_fatalities = to_number(sum_of_injuries_and_fatalities)
  )
# CHECK:    both numeric columns converted without creating missing values.
check_no_missing(injuries, c("year", "sum_of_injuries_and_fatalities"), "injuries numeric fields")

# FOUND:    count_values(injuries, "injury_mode") shows the source spelling
#           "VEHICLE PASSENGR"; count_values(injuries, "gender") shows "Others".
# DECISION: standardize_text() fixes case and spacing; recode_values() corrects the
#           documented Injury Mode spelling without merging the "Others" category.
injuries <- injuries |>
  mutate(across(
    c(injury_severity, age_group, gender, traffic_control, injury_mode),
    ~ standardize_text(.x, case = "title")
  )) |>
  mutate(injury_mode = recode_values(
    injury_mode,
    c("Vehicle Passengr" = "Vehicle Passenger")
  ))
# CHECK:    the mode labels are standardized and the known misspelling is absent.
check_allowed(
  injuries$injury_mode,
  c("Bicyclist", "E-Scooter Rider", "Motorcyclist", "Other", "Pedestrian",
    "Unknown", "Vehicle Driver", "Vehicle Passenger"),
  "injury_mode"
)

check_key(injuries, TABLES$injuries$key, "injuries")
save_csv(injuries, "data/interim/injuries_clean.csv")

log_msg("02_clean: done")
