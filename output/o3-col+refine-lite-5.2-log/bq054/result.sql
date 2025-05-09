-- Top 10 tree species: totals, alive/dead counts by census year and growth 1995→2015
WITH all_census AS (
  SELECT 1995 AS yr, UPPER(spc_latin) AS latin_name, status
  FROM `bigquery-public-data.new_york.tree_census_1995`
  UNION ALL
  SELECT 2005 AS yr, UPPER(spc_latin) AS latin_name, status
  FROM `bigquery-public-data.new_york.tree_census_2005`
  UNION ALL
  SELECT 2015 AS yr, UPPER(spc_latin) AS latin_name, status
  FROM `bigquery-public-data.new_york.tree_census_2015`
),
clean AS (
  SELECT *
  FROM all_census
  WHERE latin_name IS NOT NULL
    AND TRIM(latin_name) <> ''        -- exclude empty names
),
yearly_stats AS (
  SELECT
    latin_name,
    yr,
    COUNT(*)                                                     AS total,
    SUM(CASE WHEN LOWER(status) = 'dead' THEN 1 ELSE 0 END)      AS dead,
    SUM(CASE WHEN LOWER(status) <> 'dead' THEN 1 ELSE 0 END)     AS alive
  FROM clean
  GROUP BY latin_name, yr
),
pivoted AS (
  SELECT
    latin_name,
    MAX(IF(yr = 1995, total, NULL))  AS total_1995,
    MAX(IF(yr = 1995, alive, NULL))  AS alive_1995,
    MAX(IF(yr = 1995, dead , NULL))  AS dead_1995,
    MAX(IF(yr = 2005, total, NULL))  AS total_2005,
    MAX(IF(yr = 2005, alive, NULL))  AS alive_2005,
    MAX(IF(yr = 2005, dead , NULL))  AS dead_2005,
    MAX(IF(yr = 2015, total, NULL))  AS total_2015,
    MAX(IF(yr = 2015, alive, NULL))  AS alive_2015,
    MAX(IF(yr = 2015, dead , NULL))  AS dead_2015
  FROM yearly_stats
  GROUP BY latin_name
),
with_growth AS (
  SELECT
    *,
    (total_2015 - total_1995) AS total_growth_95_15,
    (alive_2015 - alive_1995) AS alive_growth_95_15,
    (dead_2015  - dead_1995)  AS dead_growth_95_15
  FROM pivoted
)
SELECT
  wg.latin_name,
  ts.species_common_name,
  total_1995, alive_1995, dead_1995,
  total_2005, alive_2005, dead_2005,
  total_2015, alive_2015, dead_2015,
  total_growth_95_15,
  alive_growth_95_15,
  dead_growth_95_15
FROM with_growth AS wg
LEFT JOIN `bigquery-public-data.new_york.tree_species` AS ts
  ON UPPER(ts.species_scientific_name) = wg.latin_name
WHERE total_1995 IS NOT NULL           -- ensure species existed in 1995
ORDER BY total_growth_95_15 DESC, wg.latin_name
LIMIT 10;