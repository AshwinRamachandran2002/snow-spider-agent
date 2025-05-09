-- Top 10 tree species (Latin name in UPPERCASE) ranked by the change
-- in total tree counts between the 1995 and 2015 NYC street‑tree censuses
WITH union_census AS (
  -- 1995 census
  SELECT
    1995 AS census_year,
    UPPER(spc_latin)            AS latin_name,
    spc_common                  AS common_name,
    status
  FROM `bigquery-public-data.new_york.tree_census_1995`
  
  UNION ALL
  -- 2005 census
  SELECT
    2005,
    UPPER(spc_latin),
    spc_common,
    status
  FROM `bigquery-public-data.new_york.tree_census_2005`
  
  UNION ALL
  -- 2015 census
  SELECT
    2015,
    UPPER(spc_latin),
    spc_common,
    status
  FROM `bigquery-public-data.new_york.tree_census_2015`
),
filtered AS (
  SELECT
    census_year,
    latin_name,
    common_name,
    CASE
      WHEN LOWER(status) LIKE '%dead%' THEN 1
      ELSE 0
    END                       AS is_dead
  FROM union_census
  WHERE latin_name IS NOT NULL
        AND TRIM(latin_name) <> ''
),
yearly_counts AS (
  SELECT
    latin_name,
    ANY_VALUE(common_name)           AS common_name,
    census_year,
    COUNT(*)                         AS total_trees,
    SUM(is_dead)                     AS dead_trees,
    COUNT(*) - SUM(is_dead)          AS alive_trees
  FROM filtered
  GROUP BY latin_name, census_year
),
pivoted AS (
  SELECT
    latin_name,
    common_name,
    
    -- 1995 counts
    COALESCE(SUM(CASE WHEN census_year = 1995 THEN total_trees END),0) AS total_1995,
    COALESCE(SUM(CASE WHEN census_year = 1995 THEN alive_trees END),0) AS alive_1995,
    COALESCE(SUM(CASE WHEN census_year = 1995 THEN dead_trees  END),0) AS dead_1995,
    
    -- 2005 counts
    COALESCE(SUM(CASE WHEN census_year = 2005 THEN total_trees END),0) AS total_2005,
    COALESCE(SUM(CASE WHEN census_year = 2005 THEN alive_trees END),0) AS alive_2005,
    COALESCE(SUM(CASE WHEN census_year = 2005 THEN dead_trees  END),0) AS dead_2005,
    
    -- 2015 counts
    COALESCE(SUM(CASE WHEN census_year = 2015 THEN total_trees END),0) AS total_2015,
    COALESCE(SUM(CASE WHEN census_year = 2015 THEN alive_trees END),0) AS alive_2015,
    COALESCE(SUM(CASE WHEN census_year = 2015 THEN dead_trees  END),0) AS dead_2015
  FROM yearly_counts
  GROUP BY latin_name, common_name
)
SELECT
  latin_name                              AS latin_name_uppercase,
  common_name,
  
  total_1995,  alive_1995,  dead_1995,
  total_2005,  alive_2005,  dead_2005,
  total_2015,  alive_2015,  dead_2015,
  
  -- growth from 1995 to 2015
  total_2015  - total_1995               AS total_growth_95_15,
  alive_2015  - alive_1995               AS alive_growth_95_15,
  dead_2015   - dead_1995                AS dead_growth_95_15
FROM pivoted
ORDER BY total_growth_95_15 DESC
LIMIT 10;