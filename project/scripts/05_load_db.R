# scripts/05_load_db.R -- store the four tables in SQLite with their keys and links.
# Reads: data/processed/*.csv        Writes: DB_PATH (config.R)
# The database is built by this script: never edit it by hand -- change a script and rerun.
source("config.R")
source("R/load_functions.R")
log_msg("05_load_db: start")

severity  <- read.csv("data/processed/severity.csv")
locations <- read.csv("data/processed/locations.csv")
temporal  <- read.csv("data/processed/temporal.csv")
injuries  <- read.csv("data/processed/injuries.csv")

con <- db_connect_fresh(DB_PATH)

# Parent table first, then child tables that reference it (FOREIGN KEY)
db_write(con, "severity",  severity,  key = "year")
db_write(con, "locations", locations, key = TABLES$locations$key,
         references = c(year = "severity"))
db_write(con, "temporal",  temporal,  key = TABLES$temporal$key,
         references = c(year = "severity"))
db_write(con, "injuries",  injuries,  key = TABLES$injuries$key,
         references = c(year = "severity"))

print(db_tables(con))
dbDisconnect(con)
log_msg("05_load_db: done -- ", DB_PATH)
