DATA220 Lab 8 — Person 1 handoff (A2, A3, B1)

Contains ONLY files edited for Person 1 tasks, extracted from the reviewed team ZIP.

A2: weather/config.R, weather/scripts/02_clean.R, weather/data/sample/weather/page_001.json and page_002.json.
A3: weather/sql/q5_deep_snow_days.sql.
B1: project/config.R (temporal dataset API URL, fields, page settings, saved-sample switch).

IMPORTANT
1. First apply the official DATA220_Lab8_Update.zip to the shared Lab 7 repository, if not done already.
2. Copy the weather/ and project/ directories from this handoff ZIP into the repository; merge folders and replace matching files. Do not replace teammate's B2-B4 scripts.
3. B2 must update project/scripts/01_extract.R to use api_get_pages() and read_json_records() rather than read_raw_csv(SOURCES$temporal$file).
4. B3 must run the API live and commit project/data/sample/temporal/*.json, then leave USE_SAVED_SAMPLE <- TRUE in project/config.R.
5. B4 must clean and validate the new temporal API table, whose column names may differ from the CSV.
6. Part C: teammate fills SUBMISSION_LAB8.md; both pipelines should be run from a fresh R session before submission.

A3 independently verified from two weather JSON pages:
  2026-01: 31; 2026-02: 27; 2026-03: 16.
A2 weather records: 180; 2 JSON pages; one Feb EDM-A snow-depth value missing (not counted).

This handoff is NOT the full final submission ZIP and should not be submitted as the complete group project.
