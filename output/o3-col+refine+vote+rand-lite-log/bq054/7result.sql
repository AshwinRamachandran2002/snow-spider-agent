/*  Top-10 NY tree species by increase in total count (1995 → 2015)
    – Shows totals, alive & dead counts for 1995, 2005, 2015
    – Includes growth for each metric
*/
WITH
-- 1995 census ---------------------------------------------------------------
y1995 AS (
  SELECT
    UPPER(spc_latin)                                       AS latin_name,
    MAX(spc_common)                                        AS common_name,
    COUNT(*)                                               AS total_1995,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 1 END) AS dead_1995,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 0 ELSE 1 END) AS alive_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
),

-- 2005 census ---------------------------------------------------------------
y2005 AS (
  SELECT
    UPPER(spc_latin)                                       AS latin_name,
    COUNT(*)                                               AS total_2005,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 1 END) AS dead_2005,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 0 ELSE 1 END) AS alive_2005
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
),

-- 2015 census ---------------------------------------------------------------
y2015 AS (
  SELECT
    UPPER(spc_latin)                                       AS latin_name,
    COUNT(*)                                               AS total_2015,
    SUM(CASE WHEN LOWER(status) = 'dead'  THEN 1 END)      AS dead_2015,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 END)      AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
)

-- Final join & ranking ------------------------------------------------------
SELECT
  y2015.latin_name,
  y1995.common_name,

  -- totals
  y1995.total_1995,
  y2005.total_2005,
  y2015.total_2015,

  -- alive counts
  y1995.alive_1995,
  y2005.alive_2005,
  y2015.alive_2015,

  -- dead counts
  y1995.dead_1995,
  y2005.dead_2005,
  y2015.dead_2015,

  -- growth 1995 → 2015
  y2015.total_2015 - y1995.total_1995  AS growth_total_1995_2015,
  y2015.alive_2015 - y1995.alive_1995  AS growth_alive_1995_2015,
  y2015.dead_2015  - y1995.dead_1995   AS growth_dead_1995_2015

FROM y2015
JOIN y1995 USING (latin_name)          -- keep species present in 1995
LEFT JOIN y2005 USING (latin_name)

ORDER BY growth_total_1995_2015 DESC
LIMIT 10;