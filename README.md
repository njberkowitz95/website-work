# website-work

Source behind the interactive career map on
[noahberkowitzgeo.com/resume/](https://noahberkowitzgeo.com/resume/) — the SQL
that drives it, the embed markup, and enough notes on the CARTO Builder
configuration to rebuild it from scratch.

The map itself is a CARTO Builder map, so there is no application code: the
logic lives in two BigQuery queries and a handful of Builder settings. This repo
captures both, because the Builder settings are otherwise invisible and easy to
lose.

## Layout

```
sql/01_map_points.sql          points layer — one row per role or degree
sql/02_career_path_line.sql    line layer — chronological path via ST_MAKELINE
wordpress/career-map-section.html   the embed section on the Résumé page
```

## Data

One BigQuery table in the CARTO Data Warehouse,
`carto-dw-ac-cy43l3xe.shared.career_locations` — 11 rows, 8 roles and 3 degrees.
Both queries read it; nothing writes to it.

| column | type | notes |
| --- | --- | --- |
| `geom` | GEOGRAPHY | point, geocoded from `location_note` |
| `id` | STRING | stable slug, e.g. `fremont`, `clarklabs` |
| `kind` | STRING | `role` or `education` |
| `org`, `role` | STRING | organisation and job or degree title |
| `city`, `state`, `place` | STRING | `place` is the display form, "Lincoln, NE" |
| `category`, `category_label` | STRING | discipline slug and display label |
| `color` | STRING | hex per discipline |
| `start_date`, `end_date` | DATE | `end_date` is NULL for the current role |
| `start_year`, `end_year` | INT64 | |
| `date_range` | STRING | "Oct 2024 — present" |
| `months` | INT64 | duration in months |
| `duration_label` | STRING | "1 yr 4 mo" |
| `is_current` | BOOL | |
| `summary` | STRING | prose description shown in the popup |
| `tools` | STRING | toolkit on roles, short note on degrees |
| `location_note` | STRING | street address, geocoding input |
| `sequence` | INT64 | chronological order across roles *and* degrees |

`kind`, `months` and `tools` each do double duty, which is why the points query
derives `entry_type`, `work_months`, and a split `tools` / `note`. See the
comments in that file.

## Builder configuration

**Sources** — two, both SQL queries against the table above.

**Layers**

| layer | source | style |
| --- | --- | --- |
| Roles & degrees | `01_map_points.sql` | point; radius by `months`, 6–26px; colour by `category_label`, ordinal palette; 90% opacity |
| Career path | `02_career_path_line.sql` | line; 2px stroke, 80% opacity |

Points sit above the line in the layer list. The line layer has no popup.

**Widgets** — all bound to the points source.

| widget | type | field | notes |
| --- | --- | --- | --- |
| Discipline | Category | `category_label` | six categories; the viewer collapses the sixth under "Others" until expanded |
| Career timeline | Time Series | `start_date` | bar style, yearly interval |
| Months worked | Formula | `work_months` | SUM — 145 |
| Every post, listed | Table | `entry`, `organisation`, `location`, `dates`, `duration` | cross-filters with the rest |

**Popup** (click + hover, light theme) — `role`, `organisation`, `location`,
`dates`, `duration`, `summary`, `tools`, `note`, `address`.

Field labels come from the SQL aliases. Builder's own per-field label inputs
accept text but do not persist it, so renaming in SQL is the reliable route.

**Initial view** — fitted to the points layer, then one zoom step out, so the
Nebraska entries stay in frame at embed width. Fit alone lands at zoom 5, which
clips at the ~680px the iframe gets on a laptop.

## Publishing

Builder autosaves the editor continuously, but a **public map serves a
published snapshot**. Editor changes do not reach the embed until:

> Share ▸ **Publish updates**

This applies to the viewport as well as data and styling. If a change looks like
it did not take, this is almost always why.

## Notes

- The Rowan BS is filtered out of the map (`WHERE id != 'rowan'` in both
  queries) while remaining in the Education section of the résumé page. Remove
  that line from both files to restore it, then publish updates.
- The path query's label reads "Career path, 2017 to present" because Monmouth
  County is the earliest entry once Rowan is excluded.
- Swap the `carto-dw-…` project reference for your own if you fork this.
