WITH tree_union AS (
  -- 1995 inventory
  SELECT
    UPPER(spc_latin)                           AS latin,
    spc_common                                 AS common,
    CASE WHEN LOWER(status) LIKE '%dead%' 
         THEN 'dead' ELSE 'alive' END          AS life_status,
    1995                                        AS yr
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''

  UNION ALL
  -- 2005 inventory
  SELECT
    UPPER(spc_latin)                           AS latin,
    spc_common                                 AS common,
    CASE WHEN LOWER(status) LIKE '%dead%' 
         THEN 'dead' ELSE 'alive' END          AS life_status,
    2005                                        AS yr
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''

  UNION ALL
  -- 2015 inventory
  SELECT
    UPPER(spc_latin)                           AS latin,
    spc_common                                 AS common,
    CASE WHEN LOWER(status) LIKE '%dead%' 
         THEN 'dead' ELSE 'alive' END          AS life_status,
    2015                                        AS yr
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
)

SELECT
  latin                                         AS latin_name,
  ANY_VALUE(common)                             AS common_name,
  -- totals by year
  COUNTIF(yr = 1995)                            AS total_1995,
  COUNTIF(yr = 2005)                            AS total_2005,
  COUNTIF(yr = 2015)                            AS total_2015,
  -- alive by year
  COUNTIF(yr = 1995 AND life_status = 'alive')  AS alive_1995,
  COUNTIF(yr = 2005 AND life_status = 'alive')  AS alive_2005,
  COUNTIF(yr = 2015 AND life_status = 'alive')  AS alive_2015,
  -- dead by year
  COUNTIF(yr = 1995 AND life_status = 'dead')   AS dead_1995,
  COUNTIF(yr = 2005 AND life_status = 'dead')   AS dead_2005,
  COUNTIF(yr = 2015 AND life_status = 'dead')   AS dead_2015,
  -- growth from 1995 to 2015
  COUNTIF(yr = 2015)  - COUNTIF(yr = 1995)      AS total_growth,
  COUNTIF(yr = 2015 AND life_status = 'alive') 
    - COUNTIF(yr = 1995 AND life_status = 'alive') AS alive_growth,
  COUNTIF(yr = 2015 AND life_status = 'dead')  
    - COUNTIF(yr = 1995 AND life_status = 'dead')  AS dead_growth
FROM tree_union
GROUP BY latin
ORDER BY total_growth DESC
LIMIT 10;