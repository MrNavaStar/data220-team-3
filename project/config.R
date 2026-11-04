# config.R -- YOUR project's data: the sources, what you found in them, and the tables
# you plan. Lab 7 starts it; Lab 8 builds on it. Write names exactly as in SUBMISSION.md.

PROJECT <- "Analyzing Traffic Collisions and Road Safety in Edmonton"

# =============================================================================
# P1 -- Sources: one entry per data source
# -----------------------------------------------------------------------------
#   what   : one line -- what the data are
#   format : "csv", "several csv", "excel", "json", "api" or "other"
#   get    : "download" (a file from a portal or a person) or "api" (Lab 8 calls it)
#   link   : where it comes from: a web page, a portal, an API address
#   file   : the file or folder in data/raw/ -- for an API source, a saved SAMPLE
#            response (P2)
#   owner  : who looks after this source; several people: "Alex Example, Sam Example"
# Example (delete it and write your own):
#   sales = list(what = "Daily sales from the cart's till, one export per month",
#                format = "several csv", get = "download",
#                link = "emailed by Campus Food Services",
#                file = "data/raw/sales", owner = "Alex Example"),
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
    format = "csv",
    get = "download",
    link = "https://data.edmonton.ca/d/jduq-w5pj",
    file = "data/raw/collision_temporal.csv",
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
# P3 -- What you found (run scripts/00_inspect_sources.R first)
# -----------------------------------------------------------------------------
# One "# FOUND:" line per problem you will have to clean or decide -- at least two:
#   FOUND (example): sales Date is in 2 formats (2026-10-01, 10/15/2026) -> parse_dates_mixed()
#
# =============================================================================
# FOUND: top_collision_locations LOCATION TYPE mixes case and naming variants ("Intersection", "INTERSECTION", "Midblock", "MID STREET") -> standardize_text() + recode_values()
# FOUND: collision_injuries Injury Mode has spelling variants ("VEHICLE PASSENGR", "VEHICLE PASSENGER") -> standardize_text() + recode_values()
# FOUND: collision_temporal Collision_Classification has mixed capitalization and labels ("Minor", "Serious", "Fatal", "Major", "PDO") -> standardize_text(case = "title") + recode_values()
# FOUND: collision_injuries Injury Gender includes both explicit categories and a catch-all label ("MALE", "FEMALE", "UNKNOWN", "Others") -> standardize_text(case = "title") + recode_values()
# FOUND: locations ranks tie within year/type, so (year, location_type, rank) repeats; adding location_description makes the raw-data key unique.
# FOUND: temporal rows differ by season and hour group; the six-field Lab 7 key repeats, while the complete eight-field dimension key is unique in the raw CSV.
# CHECK: verify these candidate keys again with check_key() after cleaning, as capitalization/recode decisions may change the records.

# =============================================================================
# P4 -- The tables you plan (preliminary: they may change once you know your data)
# -----------------------------------------------------------------------------
#   grain : what ONE row is ("one row per item per day")
#   key   : the column(s) that identify one row -- never repeated, never missing
#   owner : who builds it; a table can have several owners: "Alex Example, Sam Example"
# Example:
#   sales = list(grain = "one row per item per day", key = c("item", "date"), owner = "Alex Example"),
#   items = list(grain = "one row per menu item",    key = "item",            owner = "Sam Example"),
# =============================================================================
TABLES <- list(
  severity = list(grain = "one row per year", key = "year", owner = "Ethan Stevenson"),
  locations = list(grain = "one row per year, location type, rank, and location description (tied ranks allowed)",
                   key = c("year", "location_type", "rank", "location_description"),
                   owner = "Ethan Stevenson"),
  temporal = list(grain = "one row per year, season, month, hour, hour group, weekend flag, weekday, and collision classification",
                  key = c("year", "season", "month_name", "hour", "hour_group", "weekend_flag", "day_of_week", "collision_classification"),
                  owner = "Vedsai Vangapandu"),
  injuries = list(grain = "one row per year, injury severity, age group, gender, traffic control, and road-user mode",
                  key = c("year", "injury_severity", "age_group", "gender", "traffic_control", "injury_mode"),
                  owner = "Vedsai Vangapandu")
)

# How the tables link: child -> parent, through a shared key column. E.g.
#   list(child = "sales", parent = "items", key = "item")
LINKS <- list(
  list(child = "locations", parent = "severity", key = "year"),
  list(child = "temporal", parent = "severity", key = "year"),
  list(child = "injuries", parent = "severity", key = "year")
)
