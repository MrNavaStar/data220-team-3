# R/functions_api.R -- M2 Task 1: reproducible Socrata API downloads using httr2.
# Functions: api_log_request(), api_build_request(), api_count_rows(),
#            api_dataset_metadata(), api_get_and_save_httr2(),
#            api_get_pages_httr2(), api_write_manifest()
#
# Design
#   * Every HTTP request (success, HTTP error or network failure) is appended to
#     logs/api_log.txt:  time | status | records | URL | saved file
#   * Each page's response bytes are written unchanged (writeBin) -- the City's
#     original JSON is preserved; parsing happens later in read_json_records().
#   * Truncation guard: before paging, the server's own count(*) is requested;
#     after paging, the rows actually saved must equal that count, and a full
#     final page at max_pages stops the script instead of silently truncating.
#   * Pages are downloaded to a temporary staging folder first, so a failed run
#     never overwrites the last known-good page set.
#   * An optional Socrata app token is read from the environment variable
#     SOCRATA_APP_TOKEN (or APP_TOKEN). Put it in a user-level ~/.Renviron --
#     never in config.R or any file tracked by Git. No token is required for
#     these public datasets.

api_log_request <- function(status, url, file, n_records = NA) {
  dir.create("logs", recursive = TRUE, showWarnings = FALSE)
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", status, " | ",
      ifelse(is.na(n_records), "-", n_records), " records | ",
      url, " | ", file, "\n", sep = "",
      file = "logs/api_log.txt", append = TRUE)
}

# Build an httr2 request with query parameters, timeout, retries and token.
api_build_request <- function(url, query = list()) {
  req <- httr2::request(url)
  if (length(query)) {
    req <- do.call(httr2::req_url_query, c(list(.req = req), query))
  }
  token <- Sys.getenv("SOCRATA_APP_TOKEN", unset = Sys.getenv("APP_TOKEN", unset = ""))
  if (nzchar(token)) req <- httr2::req_headers(req, `X-App-Token` = token)
  req |>
    httr2::req_user_agent("DATA220 student project (httr2)") |>
    httr2::req_timeout(60) |>
    httr2::req_retry(max_tries = 3) |>          # retries 429/503 responses
    httr2::req_error(is_error = function(resp) FALSE)  # we inspect status ourselves
}

# Perform a request; log network failures and non-200 statuses, then stop.
api_perform_logged <- function(req, logged_file) {
  response <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      api_log_request("NETWORK-ERROR", req$url, logged_file)
      stop("API request failed before a response was received: ", req$url,
           "\n  ", conditionMessage(e),
           "\n  Offline? Set USE_SAVED_SAMPLE <- TRUE to use data/sample/.")
    }
  )
  status <- httr2::resp_status(response)
  if (status != 200) {
    api_log_request(status, httr2::resp_url(response), logged_file)
    stop("API status ", status, " for ", httr2::resp_url(response), ": ",
         substr(httr2::resp_body_string(response), 1, 350))
  }
  response
}

# Ask the server how many rows the query matches ($select=count(*)).
api_count_rows <- function(url, where = NULL) {
  query <- list(`$select` = "count(*)")
  if (!is.null(where)) query[["$where"]] <- where
  response <- api_perform_logged(api_build_request(url, query), "(row count)")
  parsed <- jsonlite::fromJSON(httr2::resp_body_string(response, encoding = "UTF-8"))
  n <- as.integer(parsed[[1]][1])
  api_log_request(200, httr2::resp_url(response), "(row count)", n)
  if (is.na(n)) stop("Could not read count(*) from ", url)
  n
}

# Dataset metadata from the Socrata views API (name, licence, last update).
# https://data.edmonton.ca/api/views/<id>.json
api_dataset_metadata <- function(resource_url) {
  id <- sub("\\.json$", "", basename(resource_url))
  meta_url <- sub("/resource/.*$", paste0("/api/views/", id, ".json"), resource_url)
  response <- api_perform_logged(api_build_request(meta_url), "(metadata)")
  api_log_request(200, meta_url, "(metadata)")
  m <- jsonlite::fromJSON(httr2::resp_body_string(response, encoding = "UTF-8"))
  as_utc <- function(x) if (is.null(x)) NA_character_ else
    format(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d %H:%M:%S UTC")
  list(
    dataset_id = id,
    name = m$name,
    licence = if (is.null(m$license$name)) NA_character_ else m$license$name,
    rows_updated_at = as_utc(m$rowsUpdatedAt),
    metadata_updated_at = as_utc(m$viewLastModified),
    fields = paste(m$columns$fieldName, collapse = ";")
  )
}

# One page request: save the exact response bytes; return the record count.
api_get_and_save_httr2 <- function(url, file, query = list(), logged_file = file) {
  response <- api_perform_logged(api_build_request(url, query), logged_file)
  requested_url <- httr2::resp_url(response)
  body_raw <- httr2::resp_body_raw(response)
  body_txt <- rawToChar(body_raw)
  Encoding(body_txt) <- "UTF-8"
  records <- jsonlite::fromJSON(body_txt, simplifyVector = FALSE)
  if (!is.list(records) || !is.null(names(records))) {
    api_log_request("BAD-JSON", requested_url, logged_file)
    stop("Unexpected API response (expected a JSON array) from ", requested_url)
  }
  api_log_request(200, requested_url, logged_file, length(records))
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  writeBin(body_raw, file)   # original response bytes, unaltered
  log_msg("API status 200: ", length(records), " records -> ", logged_file)
  Sys.sleep(1)               # polite rate limit (Week 10)
  length(records)
}

# Paginated Socrata request, or the offline saved-sample folder.
# RETURNS the page files; attribute "download" holds live-run details.
api_get_pages_httr2 <- function(url, folder, fields = "*", where = NULL,
                                page_size = 1000, max_pages = 25,
                                use_saved = TRUE) {
  if (use_saved) {
    files <- sort(list.files(folder, pattern = "^page_[0-9]+\\.json$",
                             full.names = TRUE))
    if (!length(files)) stop("No saved API sample in ", folder,
                             ". Run scripts/refresh_api_samples.R once while online.")
    log_msg("API offline (USE_SAVED_SAMPLE): ", length(files), " page(s) in ", folder)
    return(files)
  }

  server_rows <- api_count_rows(url, where)
  needed_pages <- ceiling(server_rows / page_size)
  if (needed_pages > max_pages) {
    stop(url, " reports ", server_rows, " rows = ", needed_pages, " pages of ",
         page_size, ", but max_pages is ", max_pages,
         ". Raise max_pages in config.R; refusing to download a truncated table.")
  }

  stage <- tempfile("data220_api_pages_")
  dir.create(stage, recursive = TRUE)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  n_pages <- 0L
  n_total <- 0L
  for (page in seq_len(max_pages)) {
    offset <- as.integer((page - 1L) * page_size)
    # $order=:id gives a stable row order, so offsets never skip or repeat rows.
    query <- list(`$select` = fields, `$order` = ":id",
                  `$limit` = as.integer(page_size), `$offset` = offset)
    if (!is.null(where)) query[["$where"]] <- where
    stage_file <- file.path(stage, sprintf("page_%03d.json", page))
    n <- api_get_and_save_httr2(
      url, stage_file, query, logged_file = file.path(folder, basename(stage_file))
    )
    if (n == 0) {
      unlink(stage_file)
      break
    }
    n_pages <- page
    n_total <- n_total + n
    if (n < page_size) break
    if (page == max_pages) {
      stop("Reached max_pages (", max_pages, ") with a full page; raise the cap ",
           "to avoid truncating ", url)
    }
  }
  if (n_pages == 0L) stop("The API returned no records: ", url)
  if (n_total != server_rows) {
    stop("Downloaded ", n_total, " rows from ", url, " but the server count(*) is ",
         server_rows, ". Download is incomplete; previous pages were kept.")
  }

  # Replace the previous page set only after a complete, verified download.
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  incoming <- sort(list.files(stage, pattern = "^page_[0-9]+\\.json$",
                              full.names = TRUE))
  previous <- list.files(folder, pattern = "^page_[0-9]+\\.json$", full.names = TRUE)
  if (length(previous)) unlink(previous)
  if (!all(file.copy(incoming, folder, overwrite = TRUE))) {
    stop("Could not copy downloaded page files to ", folder)
  }
  log_msg("API complete: ", n_total, " rows in ", n_pages, " page(s) -> ", folder,
          " (server count(*) = ", server_rows, ")")
  files <- sort(list.files(folder, pattern = "^page_[0-9]+\\.json$", full.names = TRUE))
  attr(files, "download") <- list(server_rows = server_rows, rows_saved = n_total,
                                  pages = n_pages, page_size = page_size,
                                  retrieved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC",
                                                        tz = "UTC"))
  files
}

# Write a small CSV recording when/what was downloaded (tracked with samples).
api_write_manifest <- function(rows, path) {
  manifest <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.csv(manifest, path, row.names = FALSE)
  log_msg("API manifest: ", nrow(manifest), " source(s) -> ", path)
  invisible(manifest)
}
