# M2 Task 5 — Location type changes and ranking comparisons

**Project:** Analyzing Traffic Collisions and Road Safety in Edmonton (DATA 220, Team 3)
**Purpose:** document the location type change and the decision for comparing rankings across years.
**Data snapshot:** City of Edmonton Open Data API, dataset `mf6n-s5ts` (Top Collision Locations).

---

## 1. What changed

The Top Collision Locations dataset changes its `location_type` values starting in 2022.

| Years          | Location type values in the data                        |
|----------------|---------------------------------------------------------|
| 2019–2021      | `Intersection` (or `INTERSECTION`), `Midblock`          |
| 2022–2023      | `INTERSECTION`, `MID AVENUE`, `MID STREET`, `SOUTH OF INTERSECTION` |

**[VERIFIED]** From the raw API data (`data/sample/locations/page_001.json`):
- 2019–2021: 52–54 Intersection rows, 0 MID AVENUE/MID STREET rows, 0–77 `Midblock` rows.
- 2022–2023: 0 Intersection rows, 0 Midblock rows, 28–55 `INTERSECTION` rows, 23–38 `MID AVENUE` rows, 13–23 `MID STREET` rows, 1 `SOUTH OF INTERSECTION` row.

The City effectively **split `Midblock` into `MID AVENUE` and `MID STREET`** (and added `SOUTH OF INTERSECTION` in 2022). The ranking restarts within each location type -- the top-ranked intersection in 2022 is rank 1 again, not a continuation of the 2021 intersection ranking.

---

## 2. Cleaning decision

In `03_transform.R` and `04_validate.R` we standardize all values with `standardize_text(case = "title")`, producing the labels `Intersection`, `Midblock`, `Mid Street`, `Mid Avenue`, `South Of Intersection`.

**Decision:** We keep the cleaned labels as-is in the processed table. We do **not** merge `MID AVENUE` and `MID STREET` back into `Midblock`, because they represent distinct location categories in the City's post-2022 system, and merging them would hide a real structural change.

---

## 3. Ranking comparison decision (for Q1)

**Problem:** Rankings are per-type, so a `Midblock` location in 2021 has no direct equivalent in 2022–2023, and rank numbers restart within each type.

**Decision for Q1:** We compare rankings **within each consistent location-type category only**.

- **Intersection vs Intersection:** valid comparison across all years (after standardizing `Intersection`/`INTERSECTION`/`Midblock` to their cleaned forms). In 2019–2021 only the `Intersection` category exists; in 2022–2023 only `INTERSECTION` exists. After standardizing both to `Intersection`, the ranks are comparable within that category.
- **Midblock → Midblock:** not comparable across 2021 and 2022+. The `Midblock` type disappears after 2021, replaced by `MID AVENUE` and `MID STREET`. We do **not** attempt to combine them into a single `Midblock` category for ranking comparison. Instead, we present `MID AVENUE` and `MID STREET` rankings separately for 2022–2023, and note the change.
- **Summary ranking across all types:** not meaningful, because ranks restart within each type and the types themselves changed.

**How Q1 handles it in practice:**
1. Filter to `Intersection` rows only for cross-year ranking comparison.
2. Present `MID AVENUE` and `MID STREET` rankings separately for 2022–2023, with a note that these replace the old `Midblock` category.
3. Do not combine location types into a single ranked list.
4. Document the change explicitly in any text describing the results.

---

## 4. Why this matters

If we naively combined all location types into one ranked list:
- A `Midblock` location ranked #3 in 2021 would appear in the same list as `MID AVENUE` locations ranked #1–#40 in 2023, which is not a fair comparison (different type, different restart).
- A reader might think a specific Midblock location dropped out of the top 50, when in fact the entire category was renamed.

By comparing within categories, we avoid misleading readers about location-level changes that are actually just **labeling changes**, not real changes in collision patterns.

---

## 5. Limitations

- `SOUTH OF INTERSECTION` (1 row, 2022) has no predecessor in 2019–2021, so it cannot be compared to earlier years.
- The City's reason for splitting `Midblock` into `MID AVENUE` and `MID STREET` is not documented in the dataset metadata.
- The top-50 list is not a census -- locations ranked #51+ are never visible, so a location could drop out of the list due to a rank restart even if its collision count is unchanged.
