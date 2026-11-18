# R/functions_read.R -- getting raw files into R without changing them.
# Functions: read_raw_csv(), read_many_csv(), read_any_file(), download_csv(), check_columns(),
#            api_get_pages(), read_json_records()


# ============================================================================
# read_raw_csv(path, na = c("", "NA", "N/A"))
# LEVEL     core
# PURPOSE   Read ONE CSV file exactly as delivered: every column stays text and
#           every column name stays as written. Nothing is converted yet --
#           converting is a cleaning decision you make later.
# USE WHEN  reading any raw CSV file.
# ARGUMENTS path : the file
#           na   : text that means "missing" in this source
# RETURNS   a data frame of text columns
# EXAMPLE
#   stations <- read_raw_csv("data/raw/stations.csv")
#   #> read 2 rows x 5 columns from data/raw/stations.csv
#   stations
#   #>   station_code climate_id       station_name elevation_m   site_type
#   #> 1        EDM-A  CLASS-A01 EDMONTON STATION A         723     airport
#   #> 2        EDM-B  CLASS-B02 EDMONTON STATION B         671 city centre
# HOW THE CODE WORKS
#   1. file.exists() + stop(): a clear message if the path is wrong (Week 9, Week 5).
#   2. read.csv() with na.strings (Week 7) and two more settings:
#      colClasses = "character" keeps every value as text (so "007" stays "007"),
#      check.names = FALSE keeps names like "Max Temp (°C)" exactly as written.
#   3. Before reading, readLines() takes the file as lines of text and validUTF8() checks
#      that every line is proper UTF-8 (both new). A file saved by Excel as
#      "CSV (Comma delimited)" with accents fails this test; stopping here is better than
#      read.csv() silently reading only part of it. fileEncoding = "UTF-8" then reads
#      accents correctly.
# ============================================================================
read_raw_csv <- function(path, na = c("", "NA", "N/A")) {
  if (!file.exists(path)) stop("File not found: ", path)
  if (!all(validUTF8(readLines(path, warn = FALSE)))) {
    stop(path, " is not UTF-8 text. In Excel use Save As > 'CSV UTF-8', then try again.")
  }
  df <- read.csv(path, na.strings = na, colClasses = "character", check.names = FALSE,
                 fileEncoding = "UTF-8")
  log_msg("read ", nrow(df), " rows x ", ncol(df), " columns from ", path)
  df
}


# ============================================================================
# read_many_csv(folder, rename = NULL, expected = NULL)
# LEVEL     core
# PURPOSE   Read EVERY .csv file in a folder (e.g. one file per month) and stack
#           them into one table, checking each file before stacking.
# USE WHEN  a source comes as several files with the same columns.
# ARGUMENTS folder   : the folder that holds the files
#           rename   : optional c(old = "new") for a column that one file names differently
#           expected : optional column names every file must have
# RETURNS   one data frame with every row, plus a column source_file
# EXAMPLE
#   w <- read_many_csv("data/raw/weather", rename = c("Snow (cm)" = "Total Snow (cm)"))
#   #> read 62 rows x 19 columns from data/raw/weather/weather_2026-01.csv
#   #> read 58 rows x 19 columns from data/raw/weather/weather_2026-02.csv
#   #> read 62 rows x 19 columns from data/raw/weather/weather_2026-03.csv
#   #>   renamed column 'Snow (cm)' -> 'Total Snow (cm)'
#   #> combined 3 files -> 182 rows
#   table(w$source_file)
#   #> 
#   #> weather_2026-01.csv weather_2026-02.csv weather_2026-03.csv 
#   #>                  62                  58                  62 
# HOW THE CODE WORKS
#   1. list.files(..., full.names = TRUE) finds the files (Week 8).
#   2. A for loop reads each one with read_raw_csv(), renames, checks the columns with
#      check_columns(), and records the file name with basename() (Weeks 5, 8).
#   3. Each file's data frame is kept in a list; bind_rows() stacks them (Week 8).
#      Checking BEFORE stacking matters: bind_rows() would fill a missing column with NA
#      and hide the problem (Week 8).
# ============================================================================
read_many_csv <- function(folder, rename = NULL, expected = NULL) {
  files <- list.files(folder, pattern = "\\.csv$", full.names = TRUE)
  if (length(files) == 0) stop("No .csv files in ", folder)
  parts <- list()
  for (f in files) {
    df <- read_raw_csv(f)
    if (!is.null(rename))   df <- rename_columns(df, rename)
    if (!is.null(expected)) check_columns(df, expected, basename(f))
    df$source_file <- basename(f)
    parts[[basename(f)]] <- df
  }
  out <- bind_rows(parts)
  log_msg("combined ", length(files), " files -> ", nrow(out), " rows")
  out
}


# ============================================================================
# read_any_file(path, sheet = 1)
# LEVEL     project
# PURPOSE   Read a CSV, Excel, JSON or tab-separated file with every column as
#           text, so you can look at a new source before deciding anything.
# USE WHEN  a source is not a plain CSV file.
# ARGUMENTS path  : the file (.csv, .xlsx, .xls, .json, .tsv, .txt)
#           sheet : Excel only -- the sheet number or name
# RETURNS   a data frame of text columns
# EXAMPLE
#   counters <- read_any_file("data/raw/counters.csv")
#   #> read 4 rows x 4 columns from data/raw/counters.csv
#   names(counters)
#   #> [1] "counter_id" "location"   "trail_type" "installed" 
# HOW THE CODE WORKS
#   1. tools::file_ext() gives the ending of the file name (new: e.g. "xlsx").
#   2. if / else if picks the reader (Week 5): read_raw_csv() for CSV;
#      readxl::read_excel() for Excel (new: the readxl package reads workbooks);
#      jsonlite::fromJSON() for JSON (new here; Week 10 explains JSON);
#      read.delim() for tab-separated text (read.csv()'s partner).
#   3. A for loop turns every column into text with as.character() (Weeks 5, 7).
# ============================================================================
read_any_file <- function(path, sheet = 1) {
  if (!file.exists(path)) stop("File not found: ", path)
  type <- str_to_lower(tools::file_ext(path))
  if (type == "csv") {
    return(read_raw_csv(path))
  } else if (type %in% c("xlsx", "xls")) {
    df <- readxl::read_excel(path, sheet = sheet, col_types = "text")
  } else if (type == "json") {
    df <- jsonlite::fromJSON(path, flatten = TRUE)
    if (!is.data.frame(df)) {
      stop(path, ": the records are inside another field of this JSON file. Ask your instructor, or wait for Lab 8.")
    }
  } else if (type %in% c("tsv", "txt")) {
    df <- read.delim(path, colClasses = "character", check.names = FALSE, fileEncoding = "UTF-8")
  } else {
    stop("Cannot read .", type, " files. Save the data as CSV, or ask your instructor.")
  }
  df <- as.data.frame(df)
  for (col in names(df)) {
    df[[col]] <- as.character(df[[col]])
  }
  log_msg("read ", nrow(df), " rows x ", ncol(df), " columns from ", path)
  df
}


# ============================================================================
# download_csv(url, dest)
# LEVEL     project
# PURPOSE   Download a file from the web into data/raw/ and keep it untouched.
# USE WHEN  a portal gives you an "Export CSV" link. (Lab 8 replaces this with API requests.)
# ARGUMENTS url  : the address of the file
#           dest : where to save it, e.g. "data/raw/requests_2026.csv"
# RETURNS   dest, invisibly
# EXAMPLE
#   # download_csv("https://data.example.org/export.csv", "data/raw/example.csv")   (not run)
# HOW THE CODE WORKS
#   1. dir.create() makes sure the folder exists (Week 8).
#   2. download.file() copies the file from the web to your computer (new);
#      mode = "wb" copies it byte for byte, so nothing is changed on the way.
#   3. log_msg() records where it came from (Week 8).
# ============================================================================
download_csv <- function(url, dest) {
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  download.file(url, dest, mode = "wb", quiet = TRUE)
  log_msg("downloaded ", url, " -> ", dest)
  invisible(dest)
}


# ============================================================================
# check_columns(df, expected, name = "table")
# LEVEL     project
# PURPOSE   Stop if any column you rely on is missing (the Week 8 check).
# USE WHEN  right after reading a file, before any step that uses those columns.
# ARGUMENTS df       : a data frame
#           expected : the column names it must have
#           name     : a name for the message
# RETURNS   TRUE invisibly; stops with the missing names otherwise
# EXAMPLE
#   d <- data.frame(id = 1:2, day = c("Mon", "Tue"))
#   check_columns(d, c("id", "day"), "d")
#   try(check_columns(d, c("id", "trips"), "d"))
#   #> Error in check_columns(d, c("id", "trips"), "d") : 
#   #>   d is missing column(s): trips
# HOW THE CODE WORKS
#   1. setdiff(expected, names(df)) lists the expected names that are not there (Week 8).
#   2. If that list is not empty, stop() names them (Week 5); paste(collapse =) joins them (Week 8).
# ============================================================================
check_columns <- function(df, expected, name = "table") {
  missing <- setdiff(expected, names(df))
  if (length(missing) > 0) {
    stop(name, " is missing column(s): ", paste(missing, collapse = ", "))
  }
  invisible(TRUE)
}


# ============================================================================
# api_get_pages(url, fields, where, page_size, max_pages, raw_dir)
# LEVEL     core
# PURPOSE   Fetch every page from a paginated City of Edmonton API and save each
#           page as a JSON file.  When USE_SAVED_SAMPLE is TRUE the function
#           skips the network and reads the pre-saved pages from data/sample/.
# USE WHEN  extracting temporal (or other) data that lives behind the City of
#           Edmonton open-data API.
# ARGUMENTS url        : the .json endpoint (e.g. "https://.../resource/....json")
#           fields     : $select string (use "*" for all fields)
#           where      : $where clause character string, or NULL for none
#           page_size  : $limit value (rows per page)
#           max_pages  : safety cap on how many pages to request
#           raw_dir    : the sub-folder inside raw_dir / data/sample or data/raw/api
# RETURNS   a character vector of file paths (the saved JSON files)
# EXAMPLE
#   files <- api_get_pages(TEMPORAL_URL, TEMPORAL_FIELDS, TEMPORAL_WHERE,
#                          TEMPORAL_PAGE_SIZE, TEMPORAL_MAX_PAGES,
#                          if (USE_SAVED_SAMPLE) "data/sample" else "data/raw/api")
#   #> [1] "data/sample/temporal/page_001.json" "data/sample/temporal/page_002.json"
# HOW THE CODE WORKS
#   1. Build the base URL with $select and optional $where (stringr::str_c).
#   2. A for loop iterates page 1 .. max_pages, computing $offset each time
#      (Week 10: (page - 1) * page_size).
#   3. download.file() grabs the JSON; jsonlite::write_json() (via cat + json)
#      saves it.  The file name uses zero-padded page numbers so they sort
#      correctly.
#   4. When USE_SAVED_SAMPLE is TRUE, list.files() finds the existing pages
#      instead of making requests.
# ============================================================================
api_get_pages <- function(url, fields, where, page_size, max_pages, raw_dir) {
  # Build base URL with $select and $where
  base_url <- paste0(url, "?$select=", fields)
  if (!is.null(where)) {
    base_url <- paste0(base_url, "&$where=", URLencode(where, reserved = TRUE))
  }

  dir.create(file.path(raw_dir, "temporal"), recursive = TRUE, showWarnings = FALSE)

  if (!USE_SAVED_SAMPLE) {
    # Fetch pages from the API
    for (page in seq_len(max_pages)) {
      offset <- (page - 1) * page_size
      api_url <- paste0(base_url, "&$limit=", page_size, "&$offset=", offset)

      page_file <- file.path(raw_dir, "temporal", sprintf("page_%03d.json", page))

      # Download the JSON response
      download.file(api_url, page_file, mode = "wb", quiet = TRUE)

      # Check if the file is empty or contains only an empty array
      content <- readLines(page_file, warn = FALSE)
      if (length(content) == 0 || all(trimws(content) %in% c("", "[]"))) {
        # No more data; remove the empty file
        file.remove(page_file)
        log_msg("api: page ", page, " is empty; stopping at page ", page - 1)
        break
      }
      log_msg("api: fetched page ", page, " -> ", basename(page_file))
    }
  } else {
    # Read saved sample pages
    page_files <- list.files(
      file.path(raw_dir, "temporal"),
      pattern = "\\.json$",
      full.names = TRUE
    )
    if (length(page_files) > 0) {
      log_msg("api: using ", length(page_files), " saved page(s) from ",
             file.path(raw_dir, "temporal"))
    }
  }

  # Return list of JSON files (whether fetched or saved)
  list.files(
    file.path(raw_dir, "temporal"),
    pattern = "\\.json$",
    full.names = TRUE
  )
}


# ============================================================================
# read_json_records(folder, na = c("", "NA", "N/A"))
# LEVEL     core
# PURPOSE   Read every JSON file in a folder (one page per file), parse the
#           JSON arrays, combine into one data frame, and convert all columns
#           to character text (so nothing is converted before cleaning).
# USE WHEN  after api_get_pages() has saved page JSON files.
# ARGUMENTS folder : the directory holding page_001.json, page_002.json, ...
#           na     : text that means "missing"
# RETURNS   a data frame of text columns
# EXAMPLE
#   records <- read_json_records("data/sample/temporal")
#   #> read 478 rows x 8 columns from page_001.json
#   #> read 499 rows x 8 columns from page_002.json
#   #> combined 2 files -> 977 rows
# HOW THE CODE WORKS
#   1. list.files() finds the JSON files in the folder.
#   2. A for loop reads each file with readLines() + paste0() (to get the
#      full JSON text), then jsonlite::fromJSON() to parse it.
#   3. Every column is coerced to character with a for loop (same as
#      read_any_file for JSON).
#   4. Each page is tagged with source_file and bound together with
#      bind_rows() (Week 8).
# ============================================================================
read_json_records <- function(folder, na = c("", "NA", "N/A")) {
  json_files <- list.files(folder, pattern = "\\.json$", full.names = TRUE)
  if (length(json_files) == 0) stop("No .json files in ", folder)

  parts <- list()
  for (f in json_files) {
    json_text <- paste(readLines(f, warn = FALSE), collapse = "\n")
    df <- jsonlite::fromJSON(json_text, flatten = TRUE)

    # Convert all columns to character
    for (col in names(df)) {
      df[[col]] <- as.character(df[[col]])
    }

    # Replace empty strings with NA based on na parameter
    if (length(na) > 0 && na[1] != "") {
      df[df == ""] <- NA
    }

    df$source_file <- basename(f)
    log_msg("read ", nrow(df), " rows x ", ncol(df), " columns from ", basename(f))
    parts[[basename(f)]] <- df
  }

  out <- bind_rows(parts)
  log_msg("combined ", length(json_files), " pages -> ", nrow(out), " rows")
  out
}
