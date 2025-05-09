/* Change in the number of living trees (2015 – 1995) aggregated by fall color */
WITH
-- 1995: trees that were NOT marked as dead
alive_1995 AS (
  SELECT
    UPPER(spc_latin)            AS sci_name,
    COUNT(*)                    AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) != 'DEAD'               -- keep every status except DEAD
  GROUP BY sci_name
),

-- 2015: trees that are explicitly marked as alive
alive_2015 AS (
  SELECT
    UPPER(spc_latin)            AS sci_name,
    COUNT(*)                    AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'               -- only ALIVE trees
  GROUP BY sci_name
),

-- combine the two years, compute per‑species change
per_species_change AS (
  SELECT
    COALESCE(a15.sci_name , a95.sci_name)                           AS sci_name,
    COALESCE(a15.cnt_2015 , 0)                                      AS cnt_2015,
    COALESCE(a95.cnt_1995 , 0)                                      AS cnt_1995,
    COALESCE(a15.cnt_2015 , 0) - COALESCE(a95.cnt_1995 , 0)         AS change_2015_minus_1995
  FROM alive_2015 a15
  FULL OUTER JOIN alive_1995 a95
  ON a15.sci_name = a95.sci_name
)

-- link to tree_species to get fall color and aggregate
SELECT
  ts.fall_color,
  SUM(ps.change_2015_minus_1995) AS total_change
FROM per_species_change ps
JOIN `bigquery-public-data.new_york.tree_species` ts
  ON UPPER(ts.species_scientific_name) = ps.sci_name
GROUP BY ts.fall_color
ORDER BY total_change DESC;