-- Career map — path source (CARTO Builder layer "Career path")
--
-- Collapses every career entry into a single LineString drawn in chronological
-- order, so the map shows the route rather than a scatter of unrelated points.
--
-- The dedupe step matters: ST_MAKELINE rejects repeated identical vertices, and
-- two entries share an address (Clark Labs and the Clark MS are both 950 Main
-- St, Worcester). Comparing each point's WKT against the previous one in
-- sequence order drops the repeat without dropping the stop.
--
-- `sequence` is the chronological ordering column on the table, not a row id —
-- it interleaves roles and degrees in the order they actually happened.
--
-- The filter must sit in the innermost CTE so LAG() runs over the already
-- filtered rows; excluding a row later would leave a gap the dedupe can't see.

WITH filtered AS (
  SELECT sequence, geom
  FROM `carto-dw-ac-cy43l3xe.shared.career_locations`
  WHERE id != 'rowan'
),
ordered AS (
  SELECT
    sequence,
    geom,
    ST_ASTEXT(geom) AS wkt,
    LAG(ST_ASTEXT(geom)) OVER (ORDER BY sequence) AS prev_wkt
  FROM filtered
),
deduped AS (
  SELECT sequence, geom FROM ordered
  WHERE prev_wkt IS NULL OR prev_wkt != wkt
)
SELECT
  1 AS id,
  'Career path, 2017 to present' AS label,
  ST_MAKELINE(ARRAY_AGG(geom ORDER BY sequence)) AS geom
FROM deduped
