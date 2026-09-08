-- Career map — points source (CARTO Builder layer "Roles & degrees")
--
-- One row per career entry: professional roles and degrees together, so the
-- Discipline widget, the timeline and the table widget all filter the same set.
-- An earlier version split roles and education across two sources, which meant
-- the discipline filter silently ignored the degrees.
--
-- Notes on the derived columns:
--   end_date      the current role has a NULL end_date in the table; coalescing
--                 to CURRENT_DATE() keeps it inside the timeline's range
--   entry_type    'Role' / 'Degree', so popups distinguish the two
--   work_months   months for roles only, zero for degrees. The "Months worked"
--                 formula widget sums this; summing `months` would count study
--                 time as work experience
--   tools / note  the table reuses `tools` for two purposes — a toolkit list on
--                 roles, a short note on degrees. Split here so popups show the
--                 right label for each
--   entry … address
--                 lowercase aliases used as column headers in the table widget
--                 and as field labels in popups. CARTO Builder's own label
--                 fields would not persist, so the names are set in SQL instead
--
-- The WHERE clause excludes the Rowan BS from the map only; it is still listed
-- in the Education section of the résumé page. Delete the line to bring it back.

SELECT
  geom, id, kind, org, role, city, state, place,
  category, category_label, color,
  start_date,
  COALESCE(end_date, CURRENT_DATE()) AS end_date,
  start_year, end_year, date_range, months, duration_label, is_current,
  summary, location_note, sequence,
  CASE WHEN kind = 'role' THEN 'Role' ELSE 'Degree' END AS entry_type,
  CASE WHEN kind = 'role' THEN months ELSE 0 END AS work_months,
  CASE WHEN kind = 'role' THEN tools ELSE NULL END AS tools,
  CASE WHEN kind = 'education' THEN tools ELSE NULL END AS note,
  role AS entry,
  org AS organisation,
  place AS location,
  date_range AS dates,
  duration_label AS duration,
  location_note AS address
FROM `carto-dw-ac-cy43l3xe.shared.career_locations`
WHERE id != 'rowan'
ORDER BY sequence
