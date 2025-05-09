-- Top 10 NYC tree species (by Latin name) ranked by the change in total tree counts
-- between 1995 and 2015, including alive / dead breakdowns.
WITH census AS (
  -- bring together the three available tree‑census vintages
  SELECT 1995 AS yr,
         UPPER(NULLIF(spc_latin,'')) AS latin_name,
         spc_common AS common_name,
         status
  FROM `bigquery-public-data.new_york.tree_census_1995`
  UNION ALL
  SELECT 2005 AS yr,
         UPPER(NULLIF(spc_latin,'')) AS latin_name,
         spc_common,
         status
  FROM `bigquery-public-data.new_york.tree_census_2005`
  UNION ALL
  SELECT 2015 AS yr,
         UPPER(NULLIF(spc_latin,'')) AS latin_name,
         spc_common,
         status
  FROM `bigquery-public-data.new_york.tree_census_2015`
),
filtered AS (
  -- keep only rows where a Latin name is present
  SELECT
    yr,
    latin_name,
    common_name,
    CASE
      WHEN LOWER(status) = 'dead' THEN 'dead'
      ELSE 'alive'
    END AS life_status
  FROM census
  WHERE latin_name IS NOT NULL
),
aggregated AS (
  -- counts per species per year / life‑status
  SELECT
    latin_name,
    ANY_VALUE(common_name) AS common_name,
    -- total counts
    SUM(IF(yr = 1995, 1, 0)) AS total_1995,
    SUM(IF(yr = 2005, 1, 0)) AS total_2005,
    SUM(IF(yr = 2015, 1, 0)) AS total_2015,
    -- alive
    SUM(IF(yr = 1995 AND life_status = 'alive', 1, 0)) AS alive_1995,
    SUM(IF(yr = 2005 AND life_status = 'alive', 1, 0)) AS alive_2005,
    SUM(IF(yr = 2015 AND life_status = 'alive', 1, 0)) AS alive_2015,
    -- dead
    SUM(IF(yr = 1995 AND life_status = 'dead', 1, 0)) AS dead_1995,
    SUM(IF(yr = 2005 AND life_status = 'dead', 1, 0)) AS dead_2005,
    SUM(IF(yr = 2015 AND life_status = 'dead', 1, 0)) AS dead_2015
  FROM filtered
  GROUP BY latin_name
),
growth AS (
  SELECT
    *,
    total_2015 - total_1995  AS total_growth,
    alive_2015 - alive_1995  AS alive_growth,
    dead_2015  - dead_1995   AS dead_growth
  FROM aggregated
)
SELECT
  latin_name,
  common_name,
  total_1995, total_2005, total_2015,
  alive_1995, alive_2005, alive_2015,
  dead_1995,  dead_2005,  dead_2015,
  total_growth,
  alive_growth,
  dead_growth
FROM growth
ORDER BY total_growth DESC
LIMIT 10;