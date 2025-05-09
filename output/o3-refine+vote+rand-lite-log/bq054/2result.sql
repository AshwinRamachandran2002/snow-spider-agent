-- Top 10 NY tree species by change in total population (1995 → 2015)
WITH yearly_counts AS (
  ------------------------------------------------------------------ 1995
  SELECT
    1995 AS yr,
    UPPER(TRIM(spc_latin))                       AS latin_uc,
    ANY_VALUE(spc_common)                        AS common_name,
    COUNT(*)                                     AS total_cnt,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' 
             THEN 1 ELSE 0 END)                 AS dead_cnt
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_uc

  UNION ALL
  ------------------------------------------------------------------ 2005
  SELECT
    2005 AS yr,
    UPPER(TRIM(spc_latin))                       AS latin_uc,
    ANY_VALUE(spc_common)                        AS common_name,
    COUNT(*)                                     AS total_cnt,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' 
             THEN 1 ELSE 0 END)                 AS dead_cnt
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_uc

  UNION ALL
  ------------------------------------------------------------------ 2015
  SELECT
    2015 AS yr,
    UPPER(TRIM(spc_latin))                       AS latin_uc,
    ANY_VALUE(spc_common)                        AS common_name,
    COUNT(*)                                     AS total_cnt,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' 
             THEN 1 ELSE 0 END)                 AS dead_cnt
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_uc
),

pivoted AS (
  SELECT
    latin_uc,
    ANY_VALUE(common_name)                       AS common_name,
    SUM(IF(yr = 1995, total_cnt, 0))             AS total_1995,
    SUM(IF(yr = 2005, total_cnt, 0))             AS total_2005,
    SUM(IF(yr = 2015, total_cnt, 0))             AS total_2015,
    SUM(IF(yr = 1995, dead_cnt, 0))              AS dead_1995,
    SUM(IF(yr = 2005, dead_cnt, 0))              AS dead_2005,
    SUM(IF(yr = 2015, dead_cnt, 0))              AS dead_2015
  FROM yearly_counts
  GROUP BY latin_uc
)

SELECT
  latin_uc                                        AS species_latin_upper,
  common_name,

  -- 1995
  total_1995,
  (total_1995 - dead_1995)                        AS alive_1995,
  dead_1995,

  -- 2005
  total_2005,
  (total_2005 - dead_2005)                        AS alive_2005,
  dead_2005,

  -- 2015
  total_2015,
  (total_2015 - dead_2015)                        AS alive_2015,
  dead_2015,

  -- growth 1995 → 2015
  (total_2015 - total_1995)                       AS total_growth_1995_2015,
  ((total_2015 - dead_2015) - 
   (total_1995 - dead_1995))                      AS alive_growth_1995_2015,
  (dead_2015 - dead_1995)                         AS dead_growth_1995_2015
FROM pivoted
ORDER BY total_growth_1995_2015 DESC
LIMIT 10;