/*  Top-10 NY City street-tree species by growth between the 1995 and 2015 censuses  */
WITH
-- 1995 census -------------------------------------------------------------------
base_1995 AS (
  SELECT
    UPPER(spc_latin)                     AS species_upper,
    ANY_VALUE(spc_common)               AS common_name,
    COUNT(*)                            AS total_1995,
    COUNTIF(LOWER(status) NOT LIKE 'dead%') AS alive_1995,
    COUNTIF(LOWER(status)  LIKE 'dead%')    AS dead_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) <> ''
  GROUP BY species_upper
),
-- 2005 census -------------------------------------------------------------------
base_2005 AS (
  SELECT
    UPPER(spc_latin)                     AS species_upper,
    COUNT(*)                            AS total_2005,
    COUNTIF(LOWER(status) NOT LIKE 'dead%') AS alive_2005,
    COUNTIF(LOWER(status)  LIKE 'dead%')    AS dead_2005
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) <> ''
  GROUP BY species_upper
),
-- 2015 census -------------------------------------------------------------------
base_2015 AS (
  SELECT
    UPPER(spc_latin)                     AS species_upper,
    ANY_VALUE(spc_common)               AS common_name_2015,
    COUNT(*)                            AS total_2015,
    COUNTIF(LOWER(status) NOT LIKE 'dead%') AS alive_2015,
    COUNTIF(LOWER(status)  LIKE 'dead%')    AS dead_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) <> ''
  GROUP BY species_upper
)
-- Assemble results --------------------------------------------------------------
SELECT
  b15.species_upper,
  COALESCE(b15.common_name_2015 , b95.common_name)          AS common_name,
  IFNULL(b95.total_1995 ,0)  AS total_1995,
  IFNULL(b95.alive_1995 ,0)  AS alive_1995,
  IFNULL(b95.dead_1995  ,0)  AS dead_1995,
  IFNULL(b05.total_2005 ,0)  AS total_2005,
  IFNULL(b05.alive_2005 ,0)  AS alive_2005,
  IFNULL(b05.dead_2005  ,0)  AS dead_2005,
  b15.total_2015,
  b15.alive_2015,
  b15.dead_2015,
  b15.total_2015 - IFNULL(b95.total_1995,0)  AS total_growth_95_15,
  b15.alive_2015 - IFNULL(b95.alive_1995,0)  AS alive_growth_95_15,
  b15.dead_2015  - IFNULL(b95.dead_1995 ,0)  AS dead_growth_95_15
FROM   base_2015  AS b15
LEFT JOIN base_2005 AS b05 USING(species_upper)
LEFT JOIN base_1995 AS b95 USING(species_upper)
ORDER BY total_growth_95_15 DESC
LIMIT 10;