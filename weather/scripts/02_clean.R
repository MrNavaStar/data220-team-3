
# scripts/02_clean.R -- fix values, one decision at a time.
# Reads: data/interim/*_raw.csv        Writes: data/interim/*_clean.csv
# Every step has the same three parts -- use this pattern in your own project:
#   - FOUND:    what an inspect function showed
#   - DECISION: which toolkit function fixes it, and why that is the right fix
#   - CHECK:    how we know it worked
source("config.R")
source("R/load_functions.R")
log_msg("02_clean: start")

# =============================== weather (from the API, Lab 8) =========================
weather <- read_raw_csv("data/interim/weather_raw.csv") |>
  select(-source_file)      # which page a row came from: not needed after extract

# FOUND:    the API sends every value as text, the date as "2026-01-01T00:00:00.000",
#           and names each station by number (50149, 27214).
#           Lab 8 also adds snow_on_ground_cm, the snow depth on the ground.
# DECISION: as.Date(substr(date, 1, 10)) keeps the first 10 characters (the day) before
#           converting; to_number() for the measurements, including snow depth;
#           recode_values() turns station numbers into the Lab 7 codes.
weather <- weather |>
  mutate(station_code   = recode_values(station_id, STATION_CODES),
         date           = as.Date(substr(date, 1, 10)),
         max_temp_c     = to_number(maximum_temperature_c),
         min_temp_c     = to_number(minimum_temperature_c),
         mean_temp_c    = to_number(mean_temperature_c),
         rain_mm        = to_number(total_rain_mm),
         snow_cm        = to_number(total_snow_cm),
         snow_ground_cm = to_number(snow_on_ground_cm)) |>
  select(station_code, date, max_temp_c, min_temp_c,
         mean_temp_c, rain_mm, snow_cm, snow_ground_cm)

# FOUND:    count_missing(weather) shows rain_mm and snow_cm missing on 90 rows -- every
#           EDM-B (Blatchford) day. That station does not report rain or snow, so the API
#           leaves those fields out of its records.
# DECISION: keep them NA (missing, never 0: "no snow" and "not measured" are different).
#           The analysis uses EDM-A (ANALYSIS_STATION), which reports both.
#           Missing snow-depth measurements also remain NA.
# CHECK:    the analysis station has a new-snow value on every day.
check_no_missing(filter(weather, station_code == ANALYSIS_STATION), "snow_cm", "EDM-A weather")

# CHECK:    one row per station per day (the API has no overlapping months to remove).
check_key(weather, c("station_code", "date"), "weather")
save_csv(weather, "data/interim/weather_clean.csv")

# =============================== trail counts ==========================================
counts <- read_raw_csv("data/interim/trail_counts_raw.csv")

# FOUND:    find_text_variants(counts, "counter_id") shows "rv-02" next to "RV-02" and
#           " KF-04" next to "KF-04".
# DECISION: standardize_text(), because the differences are only case and spaces.
# FOUND:    trips is text, and big counts are written with a comma ("1,110").
# DECISION: to_number(), which removes the comma before converting.
counts <- counts |>
  mutate(counter_id = standardize_text(counter_id),
         date       = as.Date(date),
         trips      = to_number(trips))

# FOUND:    show_out_of_range(counts, "trips", 0, 20000) shows one day with 99999 trips.
# DECISION: set_out_of_range_to_na(): no counter records 20,000 trips a day; it is a glitch.
counts$trips <- set_out_of_range_to_na(counts$trips, 0, 20000, "trips")

# CHECK:    one row per counter per day.
check_key(counts, c("counter_id", "date"), "trail_counts")
save_csv(counts, "data/interim/trail_counts_clean.csv")

# =============================== counters and stations =================================
# FOUND:    profile_raw_file("data/raw/counters.csv") says installed is a "date in 2 formats".
# DECISION: parse_dates_mixed(), which reads both 2019-05-14 and 06/02/2020.
counters <- read_raw_csv("data/interim/counters_raw.csv") |>
  mutate(installed = parse_dates_mixed(installed))
check_key(counters, "counter_id", "counters")
save_csv(counters, "data/interim/counters_clean.csv")

stations <- read_raw_csv("data/interim/stations_raw.csv") |>
  mutate(elevation_m = to_number(elevation_m))
check_key(stations, "station_code", "stations")
save_csv(stations, "data/interim/stations_clean.csv")

log_msg("02_clean: done")
