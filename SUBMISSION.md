# DATA 220 · M2 · Team submission

**Team number:** 3

**Project title:** Analyzing Traffic Collisions and Road Safety in Edmonton

**GitHub repository:** https://github.com/MrNavaStar/data220-team-3

## Team members

| Name | Student ID | Present at the lab | What I did |
|------|------------|--------------------|------------|
| Ethan Stevenson | 3131095 | YES | M2 - 2, 5, 6, 7, 8 |
| Vedsai Vangapandu | 3143678 | YES | M2 - 1, 3, 4 |

## M2 work completed

- **Task 1 (API extraction):** All four sources configured with `get = "api"` and `api_get_pages_httr2()` using httr2. `refresh_api_samples.R` validates live downloads against expected counts.
- **Task 2 (Joins):** `scripts/04_10_joins.R` aggregates each table to the year grain before joining severity (avoids row multiplication). Output: `output/yearly_summary.csv`.
- **Task 3 (Cross-source checks):** `scripts/04_checks.R` reconciles annual collision totals and injury counts from temporal and injuries against severity for 2019–2023. All 55 comparisons match.
- **Task 4 (Reporting change):** `m2_reporting_change_evidence.R` and `reports/M2_reporting_change_notes.md` investigate the September 2022 collision reporting methodology change and its impact on the 2021–2023 rise in recorded casualties.
- **Task 5 (Location types):** Documented in `reports/M2_location_types.md`. The Midblock type split into MID AVENUE and MID STREET in 2022. Rankings are compared within consistent location-type categories only.
- **Task 6 (Severity labels):** "Serious" (2019) and "Major" (2020–2021) are treated as the same severity tier for reconciliation. The City's injuries metadata lists only "Minor, Serious, Fatal" — Major is an undocumented alias. Documented in `config.R` P3 section and `M2_reporting_change_notes.md`.
- **Task 7 (Temporal details):** Removed `hour_group` from the temporal key in `config.R`. "Evening" covers hours 1–6 AND 19–24. March, June, September, and December each appear in two seasons. Documented in `config.R` P3 section.


