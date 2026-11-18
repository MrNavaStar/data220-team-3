# scripts/01_extract.R -- P5: read every source file and keep an untouched copy.
# Reads: data/raw/        Writes: data/interim/<source>_raw.csv
# Lab 8: temporal is now fetched via the City of Edmonton API (api_get_pages + read_json_records).
source("config.R")
source("R/load_functions.R")
make_folders()
log_msg("01_extract: start")

# =============================================================================
# TASK P5 -- for every source: read its file, then save an untouched copy
# -----------------------------------------------------------------------------
# Pick the reading function by what the source is (your profile told you):
#   one CSV file              read_raw_csv(SOURCES$<name>$file)
#   a folder of CSV files     read_many_csv(SOURCES$<name>$file)
#   Excel, JSON (an API sample) or TSV     read_any_file(SOURCES$<name>$file)
#   API pages                 api_get_pages() + read_json_records(folder)
# then save it:               save_csv(<data>, "data/interim/<name>_raw.csv")
# =============================================================================

severity_raw <- read_raw_csv(SOURCES$severity$file)
save_csv(severity_raw, "data/interim/severity_raw.csv")

locations_raw <- read_raw_csv(SOURCES$locations$file)
save_csv(locations_raw, "data/interim/locations_raw.csv")

# Temporal data comes from the City of Edmonton API (Lab 8).
# api_get_pages() fetches or locates JSON page files, then read_json_records()
# parses them into a single data frame with all columns as text.
temporal_files <- api_get_pages(
  TEMPORAL_URL, TEMPORAL_FIELDS, TEMPORAL_WHERE,
  TEMPORAL_PAGE_SIZE, TEMPORAL_MAX_PAGES,
  RAW_DIR
)
temporal_raw <- read_json_records(file.path(RAW_DIR, "temporal"))
save_csv(temporal_raw, "data/interim/temporal_raw.csv")

injuries_raw <- read_raw_csv(SOURCES$injuries$file)
save_csv(injuries_raw, "data/interim/injuries_raw.csv")

log_msg("01_extract: done")
