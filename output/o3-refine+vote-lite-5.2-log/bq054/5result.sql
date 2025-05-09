-- Top‑10 tree species by change in total count (2015 vs 1995)
WITH
-- 1995 census -----------------------------------------------------------
t95 AS (
  SELECT
    UPPER(spc_latin)              AS latin,
    ANY_VALUE(spc_common)         AS common_95,
    COUNT(*)                      AS total_1995,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 ELSE 0 END) AS alive_1995,
    SUM(CASE WHEN LOWER(status) = 'dead'  THEN 1 ELSE 0 END) AS dead_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin
),

-- 2005 census -----------------------------------------------------------
t05 AS (
  SELECT
    UPPER(spc_latin)              AS latin,
    ANY_VALUE(spc_common)         AS common_05,
    COUNT(*)                      AS total_2005,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 ELSE 0 END) AS alive_2005,
    SUM(CASE WHEN LOWER(status) = 'dead'  THEN 1 ELSE 0 END) AS dead_2005
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin
),

-- 2015 census -----------------------------------------------------------
t15 AS (
  SELECT
    UPPER(spc_latin)              AS latin,
    ANY_VALUE(spc_common)         AS common_15,
    COUNT(*)                      AS total_2015,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 ELSE 0 END) AS alive_2015,
    SUM(CASE WHEN LOWER(status) = 'dead'  THEN 1 ELSE 0 END) AS dead_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin
),

-- union of all species --------------------------------------------------
species AS (
  SELECT latin FROM t95
  UNION DISTINCT
  SELECT latin FROM t05
  UNION DISTINCT
  SELECT latin FROM t15
)

SELECT
  s.latin                                             AS species_latin,
  COALESCE(t15.common_15, t05.common_05, t95.common_95) AS common_name,

  -- 1995 counts
  COALESCE(t95.total_1995 ,0) AS total_1995,
  COALESCE(t95.alive_1995 ,0) AS alive_1995,
  COALESCE(t95.dead_1995  ,0) AS dead_1995,

  -- 2005 counts
  COALESCE(t05.total_2005 ,0) AS total_2005,
  COALESCE(t05.alive_2005 ,0) AS alive_2005,
  COALESCE(t05.dead_2005  ,0) AS dead_2005,

  -- 2015 counts
  COALESCE(t15.total_2015 ,0) AS total_2015,
  COALESCE(t15.alive_2015 ,0) AS alive_2015,
  COALESCE(t15.dead_2015  ,0) AS dead_2015,

  -- growth from 1995 to 2015
  COALESCE(t15.total_2015 ,0) - COALESCE(t95.total_1995 ,0) AS total_growth,
  COALESCE(t15.alive_2015 ,0) - COALESCE(t95.alive_1995 ,0) AS alive_growth,
  COALESCE(t15.dead_2015  ,0) - COALESCE(t95.dead_1995  ,0) AS dead_growth

FROM species s
LEFT JOIN t95 USING(latin)
LEFT JOIN t05 USING(latin)
LEFT JOIN t15 USING(latin)
ORDER BY total_growth DESC
LIMIT 10;