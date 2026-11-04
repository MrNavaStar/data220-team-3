# 1. Title, team, roles

**Project title:** Analyzing Traffic Collisions and Road Safety in Edmonton  
**Team number:** 3  
**Team members:** Ethan Stevenson and Vedsai Vangapandu  
**Repository:** https://github.com/MrNavaStar/data220-team-3

| Member | Proposed M1-to-final responsibilities |
|---|---|
| **Ethan Stevenson** | Collision Severity and Top Collision Locations sources; API sample/extraction; clean the annual and location data; maintain `severity` and `locations` tables; SQL queries/charts for Q1–Q2. |
| **Vedsai Vangapandu** | Temporal and Fatalities/Injuries sources; inspect and clean their fields; maintain `temporal` and `injuries` tables; SQL queries/charts for Q3–Q4; help build and validate SQLite. |

Both members will review the joins and final Quarto report, test `run_all.R`, and document contributions in `SUBMISSION.md`. **Role decision to confirm:** Lab 7 `config.R` currently lists Ethan as owner of all four datasets; the split above proposes sharing ownership for the remaining project work and updating `config.R` accordingly.

# 2. Questions

1. **Collision hotspots (2019–2023):** Which ranked Edmonton intersections and midblock locations have the highest reported collision counts each year, and how do the locations and rankings change over time?
2. **Annual trends and severity (2010–2023):** How have total reported collisions, property-damage-only collisions, and fatal/injury collisions changed by year, including around the September 2022 reporting change?
3. **When collisions occur (2019–2023):** Which months, weekdays/weekends, and published hour groups account for the most reported collisions, and how do these distributions vary by year and collision classification?
4. **Injury and fatality patterns (2019–2023):** How do reported injuries and fatalities vary by year, severity, and road-user mode, and how do annual casualty counts compare with the separate annual collision totals?

Each question will be answered with a reproducible SQL query and chart; the report will distinguish **collision counts** from **numbers of injured or killed people** and will not claim causation.

# 3. Sources

All four sources are City of Edmonton Open Data Portal datasets, currently saved as unmodified CSV files in `project/data/raw/`. **Licence/terms for all four:** [City of Edmonton Open Data Terms of Use](https://www.edmonton.ca/sites/default/files/public-files/documents/Web-version2.1-OpenDataAgreement.pdf); credit the City of Edmonton in the report. The datasets are public aggregated summaries, not identifiable incident-level records.

1. **Collision Severity** — owner: **Ethan**. Annual total collisions, property-damage-only, fatalities and injuries (14 rows × 42 columns, **2010–2023**). **Current method:** portal CSV download, `project/data/raw/collision_severity.csv`. **Proposed required API method:** JSON from `https://data.edmonton.ca/resource/77sf-j5rj.json` requested in R using `httr2`; save the unmodified response as `project/data/raw/collision_severity_api_sample.json`. Portal: https://data.edmonton.ca/d/77sf-j5rj.
2. **Top Collision Locations** — owner: **Ethan**. Ranked location/type/year summaries (561 rows × 5 columns, **2019–2023**). **Method:** portal CSV download, `project/data/raw/top_collision_locations.csv`; optional JSON endpoint `https://data.edmonton.ca/resource/mf6n-s5ts.json`. Portal: https://data.edmonton.ca/d/mf6n-s5ts.
3. **Collision Temporal** — proposed owner: **Vedsai**. Aggregated counts by year, season, month, hour, weekend/day and collision classification (18,545 rows × 9 columns, **2019–2023**). **Method:** portal CSV download, `project/data/raw/collision_temporal.csv`; verified JSON endpoint `https://data.edmonton.ca/resource/jduq-w5pj.json`. Portal: https://data.edmonton.ca/d/jduq-w5pj.
4. **Fatalities and Injuries** — proposed owner: **Vedsai**. Aggregated casualty counts by year, severity, age group, gender, traffic control and road-user mode (2,893 rows × 7 columns, **2019–2023**). **Method:** portal CSV download, `project/data/raw/collision_injuries.csv`; optional JSON endpoint `https://data.edmonton.ca/resource/brx6-rwhf.json`. Portal: https://data.edmonton.ca/d/brx6-rwhf.

**API/sample status:** The ZIP confirms the four CSVs, but **does not yet contain a saved JSON API response**, and `01_extract.R` currently reads only CSVs. Before M1 submission, fetch and commit the Collision Severity JSON sample. At M2, implement the live `httr2` call with a `USE_SAVED_SAMPLE` fallback, record retrieval dates, and keep raw responses unchanged.

# 4. Data audit

The observations below are from the four **actual CSVs in the team's Lab 7 ZIP**, checked against `project/config.R` and `project/scripts/02_clean.R`. Across all four files, the present CSVs have **no blank cells and no exact duplicate rows**; category values such as `UNKNOWN` still require interpretation.

- **Severity — 14 rows, 42 columns (2010–2023).** `# FOUND:` one row per year, with no repeated/missing year keys; many count/rate columns arrive as text in the Lab 7 raw reader. **DECISION:** convert counts and rates to numbers; validate `year` and distinguish overlapping totals from component measures. **CHECK:** `check_key(year)` and numeric/missingness checks.
- **Locations — 561 rows, 5 columns (2019–2023).** `# FOUND:` six recorded location-type labels include case changes (`Intersection`/`INTERSECTION`) and distinct mid-street/avenue categories. The preliminary `(year, location_type, rank)` key repeats **298 times** because ranks may tie. **DECISION:** standardize capitalization but preserve meaningful location distinctions and ties; use `(year, location_type, rank, location_description)` as the candidate key. **CHECK:** this four-field key has **zero duplicates** in the saved CSV; recheck after cleaning.
- **Temporal — 18,545 rows, 9 columns (2019–2023).** `# FOUND:` one row records hour `0` with hour group `Invalid`; `Serious` appears as a collision class in 2019 and `Major` appears from 2020 onward. The narrower key in Lab 7 `config.R` repeats **2,859 times**. **DECISION:** retain published classification labels pending a definition check, investigate the invalid hour, and preserve all eight categorical time/classification dimensions in the table key. **CHECK:** the expanded dimension key is unique in the saved CSV; verify again after transformations.
- **Injuries — 2,893 rows, 7 columns (2019–2023).** `# FOUND:` `VEHICLE PASSENGR` occurs in **685 rows**; gender includes `Others` (**48**) and `UNKNOWN` (**37**); severity uses both `SERIOUS` and `MAJOR` in different years. **DECISION:** fix the documented passenger spelling; retain unknown/other categories and do not merge severity labels without checking metadata. **CHECK:** run `check_allowed()` and `check_key()` on the six injury dimensions; that candidate key has no duplicates in the saved CSV.

**Concern:** The City's Collision Severity dataset states that **Collision Reporting Centres began in September 2022**, changing reporting and data management. Year-to-year changes near 2022–2023 may therefore reflect measurement changes as well as road conditions. Comparisons across the four sources use only their overlapping **2019–2023** years. The ranked locations dataset is not a census of all collision sites.

# 5. Table plan (preliminary)

| Cleaned SQLite table | Grain: one row per… | Proposed primary key | Source | Owner |
|---|---|---|---|---|
| `severity` | Reporting year | `year` | Collision Severity | Ethan |
| `locations` | Year × published location type × rank × location description (including tied ranks) | `(year, location_type, rank, location_description)` | Top Collision Locations | Ethan |
| `temporal` | Distinct published year, season, month, hour, hour group, weekend flag, weekday and collision class | `(year, season, month_name, hour, hour_group, weekend_flag, day_of_week, collision_classification)` | Collision Temporal | Vedsai |
| `injuries` | Year × severity × age group × gender × traffic control × road-user mode | `(year, injury_severity, age_group, gender, traffic_control, injury_mode)` | Fatalities and Injuries | Vedsai |

**Links:** `locations.year`, `temporal.year` and `injuries.year` → `severity.year`, for shared reporting years only. This enables year-level comparisons, **not** matching individual collisions across datasets. In M2 we will use `check_key()`, checked joins and SQLite primary/foreign keys, revise the two Lab 7 candidate keys flagged above, and document any further grain or terminology decisions.
