# M2 Task 4 — September 2022 collision reporting change and the 2021–2023 rise in recorded casualties

**Project:** Analyzing Traffic Collisions and Road Safety in Edmonton (DATA 220, Team 3)
**Purpose:** source-checked notes for the M2 report (Questions 2 and 4). The teammate writing the report should copy the wording in §6 and the limitations in §5.
**Data snapshot:** City of Edmonton Open Data API, retrieved 2026-11-20 (`project/data/sample/`, see `api_manifest.csv`). It is identical to the team's audited CSVs.
**Reproduce every number:** `source("scripts/m2_reporting_change_evidence.R")` writes the tables to `output/m2_reporting_*.csv`. The annual totals are also reconciled across the three sources by `scripts/04_checks.R`.

Each statement below is tagged:
- **[VERIFIED]**: stated in an official source we read, or computed directly from the data.
- **[POSSIBLE]**: a plausible explanation that no source we found confirms. It must be worded as uncertain.
- **[NOT VERIFIED]**: a claim in earlier drafts that we could not confirm. Do not use it.

---

## 1. What the data show (2021 → 2023)

Source: Collision Severity dataset (77sf-j5rj). Persons and collisions are different units.

| Year | Total collisions | PDO collisions | Minor-injury collisions | Serious-injury collisions | Fatal collisions | Minor injuries (people) | Serious injuries (people) | Fatalities (people) | Injuries + fatalities (people) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2019 | 21,943 | 19,863 | 1,822 | 244 | 14 | 2,301 | 268 | 14 | 2,583 |
| 2020 | 15,804 | 14,276 | 1,327 | 192 | 9 | 1,649 | 231 | 12 | 1,892 |
| 2021 | 17,363 | 15,674 | 1,444 | 230 | 15 | 1,816 | 259 | 16 | 2,091 |
| 2022 | 20,162 | 16,565 | 3,283 | 301 | 13 | 4,458 | 337 | 14 | 4,809 |
| 2023 | 20,039 | 12,133 | 7,581 | 304 | 21 | 10,670 | 345 | 24 | 11,039 |

**[VERIFIED] observations (descriptive, computed from the table):**

1. **Recorded injuries + fatalities rose from 2,091 (2021) to 11,039 (2023), an increase of 8,948 people (about 5.3×).**
2. **Almost all of that increase is minor injuries:** +8,854 people (1,816 → 10,670), which is 98.9% of the rise. Serious injuries rose by 86 (259 → 345) and fatalities by 8 (16 → 24).
3. **Total collisions did not rise in the same way.** They went from 17,363 (2021) to 20,162 (2022) and then 20,039 (2023). Within that total the mix shifted: PDO collisions fell from 15,674 to 12,133, while minor-injury collisions rose from 1,444 to 7,581.
4. **The change is a step in late 2022, not a gradual trend** (Temporal dataset jduq-w5pj, monthly).
   - Minor-injury collisions per month, January–September 2022: 82–192.
   - October 2022: **513**. November: **678**. December: **1,055**.
   - Every month of 2023: 526–707.
   - October 2022 PDO collisions fell to 776, from 1,453 in September. October 2021 had 135 minor-injury and 1,419 PDO collisions.
   - The data is monthly only, so it cannot show the exact date the change began.
5. **The increase is concentrated among vehicle occupants** (Fatalities and Injuries dataset brx6-rwhf, minor injuries only).
   - Vehicle drivers: 1,189 → 7,684. Vehicle passengers: 329 → 2,474.
   - Together that is +8,640 people, 97.6% of the minor-injury increase.
   - Minor injuries to pedestrians (118 → 196) and bicyclists (114 → 134) rose far less.
   - Injured people with an `UNKNOWN` road-user mode rose from 14 (2021) to 115 (2022) and 92 (2023).
6. **Severity labels change by year.**
   - Temporal: `Serious` in 2019, `Major` in 2020–2023.
   - Injuries: `SERIOUS` in 2019, `MAJOR` in 2020–2021, `SERIOUS` in 2022–2023.
   - The City's field description lists only "Minor, Serious, Fatal". In every year, both labels reconcile exactly to the Severity dataset's `serious_injury_collisions` and `total_serious_injuries` (verified in `04_checks.R`). We therefore treat them as the same tier with a different label. This is a labelling inconsistency, not evidence of a definition change.

## 2. Verified reporting-system changes (official sources)

**[VERIFIED] CRCs launched in September 2022 and changed collection and data management.** The metadata description of all three Annual Collision Report datasets (Severity, Temporal, Fatalities and Injuries) says:

> "In September 2022, CRCs were launched in Edmonton to be a centralized place for residents to report their collisions. This new process changed the collision data collection and reporting process for residents as well as how the data is managed and reported. CRCs were created as a partnership between EPS and Accident Support Services International. The CRCs have provided collision reports that differ in consistency and accuracy from the data previously received from EPS." [1][2][3]

**[VERIFIED] The City attributes the rise in minor-injury crashes to the CRC process.** The City of Edmonton *Automated Traffic Enforcement Report 2024*, section "Interpreting Crash Statistics", says:

> "The number of minor injury crashes reported in 2023 and 2024 has increased greatly compared with previous years, due to the self-reported nature of collisions and kiosk questions at CRCs. Collision report data from CRCs differs in consistency and accuracy from the data previously received from EPS."
> "There have been increased delays in receiving collision reports processed through the CRCs." [4]

**[VERIFIED] The City already cautioned about 2022 comparisons.** The *Automated Traffic Enforcement Report 2022* says that "caution must be exercised when comparing the 2022 crash numbers to the previous 3 year average". It adds that "the increase in the number of crash injuries being captured in the data … may be as a result of the process shift rather than an increase in injury causing collisions themselves." [5]

**[VERIFIED] Current CRC scope (EPS).** The Edmonton Police Service collision-reporting page says:
- Collisions are reported at a CRC run under an EPS–ASSI agreement, and EPS front counters no longer process collisions.
- Collisions with **$5,000 or more combined damage** must be reported to a CRC.
- Residents should **call 911** for collisions involving a fatality or serious injury, crime in progress, or a dangerous situation.
- They should call the **EPS non-emergency line** when any driver is taken to hospital, when a pedestrian or cyclist has been injured, and in several other listed situations.
- The CRC requirement covers collisions with $5,000+ damage that do "not involve the above situations".
- The report can be started online and completed at a CRC kiosk. [6]

The page describes *current* practice. It does not give the launch date or describe the pre-2022 process.

**[VERIFIED] COVID-19 context.** The 2022 and 2024 ATE reports describe 2020 (and 2021, in the 2024 report) as outlier years with reduced traffic volumes and crash numbers. [4][5] 2021 is therefore an unusually low baseline.

## 3. How the evidence fits together

**[VERIFIED]:**
- The timing in our data matches the CRC launch: monthly minor-injury collisions jump in October 2022, the first full month after a September 2022 launch.
- The City itself attributes the 2023–2024 rise in minor-injury crashes to self-reporting and kiosk questions at CRCs.

**[POSSIBLE], all unconfirmed by any source we found:**
- **Reclassification from PDO to minor injury.** PDO collisions fell while minor-injury collisions rose and total collisions stayed roughly flat. This is *consistent with* some collisions that would previously have been recorded as PDO being recorded as minor injury through CRC self-reporting. No source states this, and the data cannot show it, because the datasets are aggregates and individual collisions cannot be followed.
- **Why vehicle occupants dominate the increase.** Under current EPS guidance, collisions where a pedestrian or cyclist is injured, any driver goes to hospital, or someone is seriously injured or killed are reported to police (non-emergency line or 911) rather than at a CRC. That may explain why the increase is concentrated in vehicle drivers and passengers. This is our inference; the City has not said so.
- **The rise in `UNKNOWN` road-user mode in 2022–2023** may reflect the lower consistency of CRC data the City describes. Unconfirmed.
- **Other factors are possible and cannot be ruled out:** traffic volumes recovering after COVID, changes in reporting thresholds or public awareness, data-entry or processing changes, and genuine changes in road safety. We found no source quantifying any of them for 2021–2023.

**Fatalities and serious injuries (2021 → 2023: fatalities 16 → 24; serious injuries 259 → 345):**
- **[VERIFIED]** No official source we found attributes these changes to the CRC process. The City's explanation [4] refers specifically to *minor* injury crashes.
- **[VERIFIED]** Under current EPS guidance, fatal and serious-injury collisions are reported by calling 911, not at a CRC [6].
- **[POSSIBLE]** These categories may therefore be less affected by the reporting change, but the delays and data-management changes apply to all CRC-era records. We could not confirm how the pre- and post-2022 processes differ for these categories.
- **[VERIFIED from data]** Annual fatalities from 2019–2023 range from 12 to 24. With counts this small, ordinary year-to-year variation is large relative to the count, so a single-year change is weak evidence of a trend.
- **Report wording:** describe these as changes in *recorded* counts. Do not call them a verified deterioration in road safety, and do not attribute them to CRCs.

## 4. Claims removed from earlier drafts

- **[NOT VERIFIED]** "CRCs used a slightly different minor-injury definition" (attributed in the earlier draft to the 2023 ATE report).
  - The 2023 ATE PDF [7] could not be text-extracted: its fonts have no Unicode mapping, so neither pdftotext nor a web reader could read it.
  - The 2024 report attributes the rise to *self-reporting and kiosk questions*, not to a formal definition change.
  - Do not say the City changed the definition of a minor injury unless someone reads [7] manually and finds that wording.
- **[NOT VERIFIED]** "Some 2023 reports were still being received at the time of writing." The 2024 report says this about **2024** data [4]. Whether the published 2023 figures are final is not stated anywhere we found.
  - The datasets' rows were last updated on 2024-09-24, according to the portal metadata.
  - Treat 2023 as "as published", not as confirmed complete.

## 5. Limitations for the report

1. **Structural break.** 2022 mixes about 8 months of pre-CRC and about 4 months of CRC-era reporting, and 2023 is entirely CRC-era. Annual counts before and after September 2022 are not directly comparable, especially minor injuries, minor-injury collisions and PDO collisions.
2. **Recorded counts are not true occurrence.** All datasets count *reported* collisions and casualties. Under-reporting, and changes in reporting behaviour, affect the recorded numbers.
3. **Aggregated data.** Collisions cannot be linked across datasets or followed through the reporting process. Cross-source agreement holds only for annual totals (verified for 2019–2023 in `04_checks.R`).
4. **Possible incomplete 2023 data.** The City reports CRC processing delays. The datasets have not been updated since 2024-09-24.
5. **COVID baseline.** 2020–2021 had reduced traffic, so increases measured from 2021 are inflated relative to a pre-pandemic baseline. 2019 is the cleaner pre-CRC, pre-COVID comparison: minor injuries were 2,301 in 2019 and 10,670 in 2023.
6. **No exposure data.** We have no traffic-volume (vehicle-kilometres) data, so we cannot compute risk per kilometre travelled. Per-1,000-population rates are in the Severity dataset but do not account for travel.
7. **Labels.** The Serious/Major labelling is inconsistent across years and datasets (§1, item 6).
8. **Ranked locations** (mf6n-s5ts) is a top-50 list, not a census, and also comes from the post-2022 reporting system.

## 6. Ready-to-use report wording

> In September 2022, Edmonton launched Collision Reporting Centres (CRCs), which the City states "changed the collision data collection and reporting process" and produced reports that "differ in consistency and accuracy" from earlier Edmonton Police Service data [1]. In our data, monthly minor-injury collisions rose from 82–192 per month in January–September 2022 to 513 in October 2022 and stayed above 500 per month throughout 2023. Recorded injuries and fatalities increased from 2,091 people in 2021 to 11,039 in 2023, and 98.9% of that increase was minor injuries, mostly to vehicle drivers and passengers. The City attributes the rise in minor-injury crashes to "the self-reported nature of collisions and kiosk questions at CRCs" [4]. We therefore treat 2022–2023 casualty counts as affected by a change in reporting and do not interpret them as a five-fold increase in injuries on Edmonton roads. Recorded fatalities (16 in 2021, 24 in 2023) and serious injuries (259 to 345) also rose. No source we found explains those changes, and with small annual counts we describe them without claiming a cause. Collision events and injured or killed people are analysed as separate measures throughout.

**Chart guidance for Q2/Q4:** mark September 2022 with a vertical reference line on monthly charts, and label 2022–2023 annual values "CRC reporting period". Show minor injuries separately from serious injuries and fatalities so that the reporting change does not hide the smaller categories.

## 7. References

1. City of Edmonton Open Data. *Annual Collision Report: Collision Severity* (dataset 77sf-j5rj), description and metadata; rows last updated 2024-09-24. https://data.edmonton.ca/d/77sf-j5rj (metadata: https://data.edmonton.ca/api/views/77sf-j5rj.json, read 2026-11-20).
2. City of Edmonton Open Data. *Annual Collision Report: Temporal* (jduq-w5pj). https://data.edmonton.ca/d/jduq-w5pj (read 2026-11-20).
3. City of Edmonton Open Data. *Annual Collision Report: Fatalities and Injuries* (brx6-rwhf), including field descriptions ("Injuries are classified as Minor, Serious, Fatal"; "One collision could cause multiple injuries"). https://data.edmonton.ca/d/brx6-rwhf (read 2026-11-20).
4. City of Edmonton, City Operations. *Automated Traffic Enforcement Report 2024*, "Interpreting Crash Statistics". https://www.edmonton.ca/sites/default/files/public-files/assets/PDF/2024-Automated-Traffic-Enforcement-Report.pdf (text read 2026-11-20).
5. City of Edmonton. *Automated Traffic Enforcement Report 2022*, "Interpreting Crash Statistics". https://www.edmonton.ca/sites/default/files/public-files/2022-Automated-Traffic-Enforcement-Report.pdf (text read 2026-11-20).
6. Edmonton Police Service. *Collision Reporting*. https://www.edmontonpolice.ca/TrafficVehicles/TrafficCollisions/ReportACollision (read 2026-11-20; describes current practice).
7. City of Edmonton. *Automated Traffic Enforcement Report 2023*. https://www.edmonton.ca/sites/default/files/public-files/2023-Automated-Traffic-Enforcement-Report.pdf. Downloaded, but the text could not be machine-extracted; **contents not verified**. Read it manually before citing.

Data used under the City of Edmonton Open Data Terms of Use, v2.1: https://www.edmonton.ca/sites/default/files/public-files/documents/Web-version2.1-OpenDataAgreement.pdf
