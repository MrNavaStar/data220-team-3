# scripts/06_queries.R -- run every query in sql/ against the database we built and
# save each result (sql/q1_*.sql -> output/q1_*.csv).
source("config.R")
source("R/load_functions.R")
log_msg("06_queries: start")

con <- db_connect(DB_PATH)
run_sql_folder(con, "sql", "output")
dbDisconnect(con)
log_msg("06_queries: done")
