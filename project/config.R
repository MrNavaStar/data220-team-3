
# config.R -- YOUR project's data: sources, findings, and table plan.
# Lab 7 started this project; Lab 8 adds API extraction.

PROJECT <- "Analyzing Traffic Collisions and Road Safety in Edmonton"

# =============================================================================
# M2 TASK 1 -- CITY OF EDMONTON API CONFIGURATION
# =============================================================================
# All four project sources use Socrata (SODA) JSON APIs called from R via httr2.
# Paging: $limit = page_size, $offset = (page - 1) * page_size, $order = :id.
# Before paging, the server's count(*) is requested; the download stops if it
# would need more than max_pages, and stops if saved rows != count(*).
# expected_rows = the team's audited snapshot. If the City republishes a source
# with a different count, 01_extract.R stops so the change is reviewed first.
#
# Verified from https://data.edmonton.ca/api/views/<id>.json on 2026-11-20:
#   severity  77sf-j5rj  14 rows     rows updated 2024-09-24
#   locations mf6n-s5ts  561 rows    rows updated 2026-09-02 (still 561, 2019-2023)
#   temporal  jduq-w5pj  18,545 rows rows updated 2024-09-24
#   injuries  brx6-rwhf  2,893 rows  rows updated 2024-09-24
#   Licence field on all four: "See Terms of Use" -> City of Edmonton Open Data
#   Terms of Use, version 2.1 (January 2016), PDF read 2026-11-20. It grants a
#   worldwide, royalty-free licence to use, modify and distribute; credit is
#   encouraged but not required; anyone redistributing the data (our committed
#   data/sample/ JSON) must include the Terms of Use URL; no City endorsement
#   may be implied. Metadata: update frequency "Annually", "Manual" process.
#   No app token is needed; an optional SOCRATA_APP_TOKEN belongs in
#   ~/.Renviron (never in this file or Git).
OPEN_DATA_LICENSE <- "City of Edmonton Open Data Terms of Use, version 2.1 (January 2016)"
OPEN_DATA_LICENSE_URL <- "https://www.edmonton.ca/sites/default/files/public-files/documents/Web-version2.1-OpenDataAgreement.pdf"
OPEN_DATA_CREDIT <- "Source: City of Edmonton Open Data Portal (data.edmonton.ca), used under the City of Edmonton Open Data Terms of Use"

API_CONFIG <- list(
  severity = list(
    dataset_id = "77sf-j5rj",
    url = "https://data.edmonton.ca/resource/77sf-j5rj.json",
    portal = "https://data.edmonton.ca/d/77sf-j5rj",
    fields = "*", where = NULL,
    page_size = 1000, max_pages = 2, expected_rows = 14
  ),
  locations = list(
    dataset_id = "mf6n-s5ts",
    url = "https://data.edmonton.ca/resource/mf6n-s5ts.json",
    portal = "https://data.edmonton.ca/d/mf6n-s5ts",
    fields = "*", where = NULL,
    page_size = 1000, max_pages = 2, expected_rows = 561
  ),
  temporal = list(
    dataset_id = "jduq-w5pj",
    url = "https://data.edmonton.ca/resource/jduq-w5pj.json",
    portal = "https://data.edmonton.ca/d/jduq-w5pj",
    fields = "*", where = NULL,
    page_size = 1000, max_pages = 25, expected_rows = 18545
  ),
  injuries = list(
    dataset_id = "brx6-rwhf",
    url = "https://data.edmonton.ca/resource/brx6-rwhf.json",
    portal = "https://data.edmonton.ca/d/brx6-rwhf",
    fields = "*", where = NULL,
    page_size = 1000, max_pages = 5, expected_rows = 2893
  )
)

# Keep the Lab 8 temporal names available for earlier code/handouts.
TEMPORAL_URL <- API_CONFIG$temporal$url
TEMPORAL_FIELDS <- API_CONFIG$temporal$fields
TEMPORAL_WHERE <- API_CONFIG$temporal$where
TEMPORAL_PAGE_SIZE <- API_CONFIG$temporal$page_size
TEMPORAL_MAX_PAGES <- API_CONFIG$temporal$max_pages

# For grading, commit data/sample/<source>/ for EVERY API source.
# The live download folders (data/raw/api/) are ignored by Git.
# TRUE  = offline: read the committed JSON pages in data/sample/<source>/.
# FALSE = live: call the API and save the responses to data/raw/api/<source>/.
# Keep TRUE in the submitted repo. To test live without editing this file,
# start R with the environment variable DATA220_LIVE_API=true.
USE_SAVED_SAMPLE <- TRUE
if (identical(tolower(Sys.getenv("DATA220_LIVE_API")), "true")) USE_SAVED_SAMPLE <- FALSE
RAW_DIR <- if (USE_SAVED_SAMPLE) "data/sample" else "data/raw/api"
API_MANIFEST <- "data/sample/api_manifest.csv"   # retrieval record, tracked in Git

# =============================================================================
# P1 -- DATA SOURCES
# =============================================================================

SOURCES <- list(
  
  severity = list(
    what = "Annual collision totals and severity, including road-user collisions, injuries and fatalities",
    format = "api",
    get = "api",
    link = API_CONFIG$severity$url,
    portal = API_CONFIG$severity$portal,
    licence = OPEN_DATA_LICENSE, licence_url = OPEN_DATA_LICENSE_URL,
    file = "data/sample/severity",
    owner = "Ethan Stevenson"
  ),
  
  locations = list(
    what = "Top collision locations, including year, location type, rank, location description and collision count",
    format = "api",
    get = "api",
    link = API_CONFIG$locations$url,
    portal = API_CONFIG$locations$portal,
    licence = OPEN_DATA_LICENSE, licence_url = OPEN_DATA_LICENSE_URL,
    file = "data/sample/locations",
    owner = "Ethan Stevenson"
  ),
  
  temporal = list(
    what = "Annual Collision Report temporal data for examining when collisions occur",
    format = "api",
    get = "api",
    link = API_CONFIG$temporal$url,
    portal = API_CONFIG$temporal$portal,
    licence = OPEN_DATA_LICENSE, licence_url = OPEN_DATA_LICENSE_URL,
    file = "data/sample/temporal",
    owner = "Vedsai Vangapandu"
  ),
  
  injuries = list(
    what = "Annual collision fatalities and injuries",
    format = "api",
    get = "api",
    link = API_CONFIG$injuries$url,
    portal = API_CONFIG$injuries$portal,
    licence = OPEN_DATA_LICENSE, licence_url = OPEN_DATA_LICENSE_URL,
    file = "data/sample/injuries",
    owner = "Vedsai Vangapandu"
  )
  
)

# =============================================================================
# P3 -- DATA FINDINGS FROM LAB 7
# =============================================================================

# FOUND: top_collision_locations LOCATION TYPE mixes case and naming variants
# ("Intersection", "INTERSECTION", "Midblock", "MID STREET").
# DECISION: standardize_text() + recode_values().

# FOUND: collision_injuries Injury Mode has spelling variants
# ("VEHICLE PASSENGR", "VEHICLE PASSENGER").
# DECISION: standardize_text() + recode_values().

# FOUND: collision_temporal (API) column names use hyphenated snake_case
# (e.g. collision_report_year, hour_group_name). The TABLES key uses
# simplified names (year, season, month_name, hour, hour_group,
# weekend_flag, day_of_week, collision_classification).
# DECISION: rename_columns() after clean_names() aligns them.
#
# FOUND: collision_temporal Collision_Classification has mixed capitalization
# and labels ("Minor", "Serious", "Fatal", "Major", "PDO").
# DECISION: standardize_text(case = "title") + recode_values().

# FOUND: collision_injuries Injury Gender includes explicit categories
# and catch-all labels ("MALE", "FEMALE", "UNKNOWN", "Others").
# DECISION: standardize_text(case = "title") + recode_values().

# FOUND: locations ranks tie within year/type.
# Adding location_description makes the raw-data key unique.

# FOUND: temporal rows differ by season and hour group.
# The six-field Lab 7 key repeats, while the complete
# eight-field dimension key is unique in the raw CSV.

# CHECK: verify candidate keys with check_key() after cleaning.
# API records must be inspected again during Lab 8 B4.

# =============================================================================
# P4 -- PLANNED TABLES
# =============================================================================

TABLES <- list(
  
  severity = list(
    grain = "one row per year",
    key = "year",
    owner = "Ethan Stevenson"
  ),
  
  locations = list(
    grain = "one row per year, location type, rank, and location description (tied ranks allowed)",
    key = c(
      "year",
      "location_type",
      "rank",
      "location_description"
    ),
    owner = "Ethan Stevenson"
  ),
  
  temporal = list(
    grain = "one row per year, season, month, hour, hour group, weekend flag, weekday, and collision classification",
    key = c(
      "year",
      "season",
      "month_name",
      "hour",
      "hour_group",
      "weekend_flag",
      "day_of_week",
      "collision_classification"
    ),
    owner = "Vedsai Vangapandu"
  ),
  
  injuries = list(
    grain = "one row per year, injury severity, age group, gender, traffic control, and road-user mode",
    key = c(
      "year",
      "injury_severity",
      "age_group",
      "gender",
      "traffic_control",
      "injury_mode"
    ),
    owner = "Vedsai Vangapandu"
  )
  
)

# =============================================================================
# TABLE RELATIONSHIPS
# =============================================================================

LINKS <- list(
  list(
    child = "locations",
    parent = "severity",
    key = "year"
  ),
  
  list(
    child = "temporal",
    parent = "severity",
    key = "year"
  ),
  
  list(
    child = "injuries",
    parent = "severity",
    key = "year"
  )
)

# =============================================================================
# LAB 8 / M2 HANDOFF NOTES
# =============================================================================

DB_PATH <- "data/db/project.sqlite"              # built by scripts/05_load_db.R

# M2 Task 1 (done): all four API settings are in API_CONFIG above.
# B2: scripts/01_extract.R downloads all four sources with api_get_pages_httr2()
#     (R/functions_api.R) when USE_SAVED_SAMPLE is FALSE.
# B3: scripts/refresh_api_samples.R downloads all four live, verifies every
#     count, then replaces data/sample/<source>/ and data/sample/api_manifest.csv.
# B4: Clean the extracted API records, check the table key,
#     and save data/interim/<source>_clean.csv (scripts/02_clean.R).
# M2 Task 3: scripts/04_checks.R reconciles 2019-2023 annual totals.
#
# Keep USE_SAVED_SAMPLE set to TRUE for final submission.
