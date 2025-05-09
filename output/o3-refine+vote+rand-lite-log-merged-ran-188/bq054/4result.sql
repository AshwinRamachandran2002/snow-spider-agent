WITH census AS (
  -- 1995 inventory
  SELECT
    UPPER(TRIM(spc_latin))             AS latin_name,
    TRIM(spc_common)                   AS common_name,
    1995                               AS yr,
    COUNT(*)                           AS total_trees,
    SUM(CASE WHEN LOWER(TRIM(status)) = 'dead' THEN 1 ELSE 0 END) AS dead_trees,
    SUM(CASE WHEN LOWER(TRIM(status)) = 'dead' THEN 0 ELSE 1 END) AS alive_trees
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
        AND TRIM(spc_latin) <> ''
  GROUP BY latin_name, common_name
  
  UNION ALL
  
  -- 2005 inventory
  SELECT
    UPPER(TRIM(spc_latin))             AS latin_name,
    TRIM(spc_common)                   AS common_name,
    2005                               AS yr,
    COUNT(*)                           AS total_trees,
    SUM(CASE WHEN LOWER(TRIM(status)) = 'dead' THEN 1 ELSE 0 END) AS dead_trees,
    SUM(CASE WHEN LOWER(TRIM(status)) = 'dead' THEN 0 ELSE 1 END) AS alive_trees
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL
        AND TRIM(spc_latin) <> ''
  GROUP BY latin_name, common_name
  
  UNION ALL
  
  -- 2015 inventory
  SELECT
    UPPER(TRIM(spc_latin))             AS latin_name,
    TRIM(spc_common)                   AS common_name,
    2015                               AS yr,
    COUNT(*)                           AS total_trees,
    SUM(CASE WHEN LOWER(TRIM(status)) = 'dead' THEN 1 ELSE 0 END) AS dead_trees,
    SUM(CASE WHEN LOWER(TRIM(status)) = 'dead' THEN 0 ELSE 1 END) AS alive_trees
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
        AND TRIM(spc_latin) <> ''
  GROUP BY latin_name, common_name
),

pivoted AS (
  SELECT
    latin_name,
    ANY_VALUE(common_name)                              AS common_name,
    
    -- 1995 counts
    COALESCE(SUM(IF(yr = 1995, total_trees, NULL)),0)   AS total_1995,
    COALESCE(SUM(IF(yr = 1995, alive_trees, NULL)),0)   AS alive_1995,
    COALESCE(SUM(IF(yr = 1995, dead_trees , NULL)),0)   AS dead_1995,
    
    -- 2005 counts
    COALESCE(SUM(IF(yr = 2005, total_trees, NULL)),0)   AS total_2005,
    COALESCE(SUM(IF(yr = 2005, alive_trees, NULL)),0)   AS alive_2005,
    COALESCE(SUM(IF(yr = 2005, dead_trees , NULL)),0)   AS dead_2005,
    
    -- 2015 counts
    COALESCE(SUM(IF(yr = 2015, total_trees, NULL)),0)   AS total_2015,
    COALESCE(SUM(IF(yr = 2015, alive_trees, NULL)),0)   AS alive_2015,
    COALESCE(SUM(IF(yr = 2015, dead_trees , NULL)),0)   AS dead_2015
  FROM census
  GROUP BY latin_name
)

SELECT
  latin_name                                         AS species_latin_upper,
  common_name                                        AS species_common_name,
  
  -- counts by year
  total_1995,  alive_1995,  dead_1995,
  total_2005,  alive_2005,  dead_2005,
  total_2015,  alive_2015,  dead_2015,
  
  -- growth from 1995 to 2015
  (total_2015 - total_1995)  AS growth_total,
  (alive_2015 - alive_1995)  AS growth_alive,
  (dead_2015  - dead_1995)   AS growth_dead
FROM pivoted
ORDER BY growth_total DESC, species_latin_upper
LIMIT 10;