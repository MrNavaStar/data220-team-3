# scripts/01_extract.R -- M2 Task 1: ALL four sources from the City of Edmonton API.
# Reads:  live API (USE_SAVED_SAMPLE = FALSE) -> saves original JSON pages to
#         data/raw/api/<source>/page_NNN.json, or the committed offline copy in
#         data/sample/<source>/ (USE_SAVED_SAMPLE = TRUE, the default).
# Writes: data/interim/<source>_raw.csv (every field still text, plus source_file)
#         logs/api_log.txt (one line per HTTP request: status, records, URL, file)
# Stops:  if any request fails, if a download is shorter than the server's
#         count(*), or if a source's row count differs from the audited snapshot.
source("config.R")
source("R/load_functions.R")
make_folders()
log_msg("01_extract: start (", if (USE_SAVED_SAMPLE) "OFFLINE saved samples" else
  "LIVE API", ", folder ", RAW_DIR, ")")

manifest <- list()
for (source_name in names(API_CONFIG)) {
  cfg <- API_CONFIG[[source_name]]
  folder <- file.path(RAW_DIR, source_name)
  files <- api_get_pages_httr2(
    url = cfg$url, folder = folder, fields = cfg$fields,
    where = cfg$where, page_size = cfg$page_size,
    max_pages = cfg$max_pages, use_saved = USE_SAVED_SAMPLE
  )
  records <- read_json_records(folder)
  if (nrow(records) != cfg$expected_rows) {
    stop(source_name, " has ", nrow(records), " rows, expected ",
         cfg$expected_rows, " (the team's audited snapshot). ",
         "Review the API query, pagination and any newer City data before proceeding.")
  }
  log_msg(source_name, ": ", nrow(records), " rows x ", ncol(records) - 1,
          " API fields (matches expected ", cfg$expected_rows, ")")
  if (!USE_SAVED_SAMPLE) {
    manifest[[source_name]] <- c(list(source = source_name, url = cfg$url),
                                 attr(files, "download"))
  }
  save_csv(records, paste0("data/interim/", source_name, "_raw.csv"))
}

if (length(manifest)) api_write_manifest(manifest, file.path(RAW_DIR, "api_manifest.csv"))
log_msg("01_extract: all four API sources loaded")
