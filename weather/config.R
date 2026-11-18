# config.R -- the settings and decisions of the weather pipeline, in one place.
# The scripts read these values, so changing a decision means editing ONE line here.
# Lab 8: the weather now comes from the City of Edmonton's open-data API instead of
# monthly CSV files. Everything after 01_extract.R is the Lab 7 pipeline.

# The analysis question: do people use the river-valley trails less on cold or snowy days?

# ---- the database --------------------------------------------------------------------
DB_PATH <- "data/db/weather.sqlite"            # built by scripts/05_load_db.R

# ---- the weather API (Lab 8) ---------------------------------------------------------
# Weather Data (Daily), City of Edmonton open data: https://data.edmonton.ca/d/s4ws-tdws
WEATHER_URL <- "https://data.edmonton.ca/resource/s4ws-tdws.json"

# $select: the columns we ask for, separated by commas (names as the API writes them).
WEATHER_FIELDS <- "station_id,date,maximum_temperature_c,minimum_temperature_c,mean_temperature_c,total_rain_mm,total_snow_cm,snow_on_ground_cm"

# $where: which rows -- our two stations, January to March 2026 (the trail-count months).
WEATHER_WHERE <- paste("station_id in ('50149','27214')",
                       "AND date between '2026-01-01T00:00:00' AND '2026-03-31T00:00:00'")

WEATHER_PAGE_SIZE <- 100   # rows per request: 180 rows arrive in 2 pages
WEATHER_MAX_PAGES <- 10    # safety limit

# The switch (Week 10). TRUE: read the saved responses in data/sample/ -- no internet needed.
# FALSE: call the API, save the responses in data/raw/api/, log every request.
USE_SAVED_SAMPLE <- TRUE
RAW_DIR <- if (USE_SAVED_SAMPLE) "data/sample" else "data/raw/api"

# ---- decisions -----------------------------------------------------------------------
# DECISION: the API names stations by number; we use the short station codes of Lab 7.
STATION_CODES <- c("50149" = "EDM-A", "27214" = "EDM-B")

# DECISION: trail use is compared with ONE station (EDM-A), so each day has one weather row.
ANALYSIS_STATION <- "EDM-A"

# DECISION: a "snow day" has at least 2 cm of new snow.
SNOW_DAY_CM <- 2
