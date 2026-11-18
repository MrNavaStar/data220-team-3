
# config.R -- YOUR project's data: sources, findings, and table plan.
# Lab 7 started this project; Lab 8 adds API extraction.

PROJECT <- "Analyzing Traffic Collisions and Road Safety in Edmonton"

# =============================================================================
# LAB 8 -- API CONFIGURATION (B1)
# =============================================================================

# City of Edmonton Open Data
# Annual Collision Report: Temporal
# Dataset: https://data.edmonton.ca/d/jduq-w5pj

TEMPORAL_URL <- "https://data.edmonton.ca/resource/jduq-w5pj.json"

# Request all available API fields initially.
# The cleaning script will select the required columns.
TEMPORAL_FIELDS <- "*"

# No year restriction initially.
# The sample is limited using page size and maximum pages.
TEMPORAL_WHERE <- NULL

# Maximum of 2,000 records across four API pages.
TEMPORAL_PAGE_SIZE <- 500
TEMPORAL_MAX_PAGES <- 4

# TRUE: read saved JSON samples without internet.
# FALSE: download fresh data from the API.
USE_SAVED_SAMPLE <- TRUE

RAW_DIR <- if (USE_SAVED_SAMPLE) {
  "data/sample"
} else {
  "data/raw/api"
}

# =============================================================================
# P1 -- DATA SOURCES
# =============================================================================

SOURCES <- list(
  
  severity = list(
    what = "Annual collision totals and severity, including road-user collisions, injuries and fatalities",
    format = "csv",
    get = "download",
    link = "https://data.edmonton.ca/d/77sf-j5rj",
    file = "data/raw/collision_severity.csv",
    owner = "Ethan Stevenson"
  ),
  
  locations = list(
    what = "Top collision locations, including year, location type, rank, location description and collision count",
    format = "csv",
    get = "download",
    link = "https://data.edmonton.ca/d/mf6n-s5ts",
    file = "data/raw/top_collision_locations.csv",
    owner = "Ethan Stevenson"
  ),
  
  temporal = list(
    what = "Annual Collision Report temporal data for examining when collisions occur",
    format = "api",
    get = "api",
    link = TEMPORAL_URL,
    file = "data/sample/temporal",
    owner = "Vedsai Vangapandu"
  ),
  
  injuries = list(
    what = "Annual collision fatalities and injuries",
    format = "csv",
    get = "download",
    link = "https://data.edmonton.ca/d/brx6-rwhf",
    file = "data/raw/collision_injuries.csv",
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
# LAB 8 HANDOFF NOTES
# =============================================================================

DB_PATH <- "data/db/project.sqlite"              # built by scripts/05_load_db.R

# B1: API configuration is defined above.
#
# B2: Update scripts/01_extract.R to download temporal records
# using api_get_pages() when USE_SAVED_SAMPLE is FALSE.
#
# B3: After a successful API download, copy the JSON files:
# save_as_sample("data/raw/api/temporal", "data/sample/temporal")
#
# B4: Clean the extracted API records, check the table key,
# and save data/interim/temporal_clean.csv.
#
# Keep USE_SAVED_SAMPLE set to TRUE for final submission.
