# scripts/refresh_api_samples.R -- LIVE download of all 4 sources into data/sample/.
# From the project/ folder:  source("scripts/refresh_api_samples.R")
#                       or:  Rscript scripts/refresh_api_samples.R
# It does NOT modify config.R. Existing samples stay untouched until EVERY API
# is downloaded and verified (server count(*) and audited expected_rows); only
# then are data/sample/<source>/ pages and data/sample/api_manifest.csv replaced.
# Not numbered, so run_all.R never calls the network by accident.
source("config.R")
source("R/load_functions.R")
make_folders()
log_msg("refresh_api_samples: downloading all four APIs")

manifest <- list()
for (source_name in names(API_CONFIG)) {
  cfg <- API_CONFIG[[source_name]]
  folder <- file.path("data/raw/api", source_name)
  files <- api_get_pages_httr2(cfg$url, folder, cfg$fields, cfg$where,
                               cfg$page_size, cfg$max_pages, use_saved = FALSE)
  records <- read_json_records(folder)
  if (nrow(records) != cfg$expected_rows) {
    stop("Downloaded ", source_name, " has ", nrow(records),
         " rows instead of the audited ", cfg$expected_rows,
         ". Inspect the source before replacing samples.")
  }
  meta <- api_dataset_metadata(cfg$url)
  manifest[[source_name]] <- c(
    list(source = source_name, url = cfg$url, portal = cfg$portal),
    attr(files, "download"),
    meta[c("name", "licence", "rows_updated_at", "metadata_updated_at")],
    list(licence_terms = OPEN_DATA_LICENSE, licence_url = OPEN_DATA_LICENSE_URL)
  )
  log_msg("verified ", source_name, ": ", nrow(records), " records")
}

# Only reached if ALL four full downloads passed the row-count checks.
for (source_name in names(API_CONFIG)) {
  from <- file.path("data/raw/api", source_name)
  to <- file.path("data/sample", source_name)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  old <- list.files(to, pattern = "^page_[0-9]+\\.json$", full.names = TRUE)
  if (length(old)) unlink(old)
  new <- list.files(from, pattern = "^page_[0-9]+\\.json$", full.names = TRUE)
  if (!length(new) || !all(file.copy(new, to, overwrite = TRUE))) {
    stop("Could not update sample for ", source_name)
  }
  log_msg("saved ", length(new), " API sample page(s) for ", source_name)
}
api_write_manifest(manifest, API_MANIFEST)

log_msg("Samples ready; USE_SAVED_SAMPLE remains TRUE in config.R")
