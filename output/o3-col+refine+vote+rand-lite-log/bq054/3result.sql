-- Top 10 NY City tree species by increase in total count from 1995 → 2015
WITH
/* 1995 inventory --------------------------------------------------------- */
yr1995 AS (
  SELECT
    UPPER(spc_latin)                             AS latin_name,
    MAX(spc_common)                              AS common_name_95,
    COUNT(*)                                     AS total_1995,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 1 ELSE 0 END) AS dead_1995,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 0 ELSE 1 END) AS alive_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
),

/* 2005 inventory --------------------------------------------------------- */
yr2005 AS (
  SELECT
    UPPER(spc_latin)                             AS latin_name,
    COUNT(*)                                     AS total_2005,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 1 ELSE 0 END) AS dead_2005,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 0 ELSE 1 END) AS alive_2005
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
),

/* 2015 inventory --------------------------------------------------------- */
yr2015 AS (
  SELECT
    UPPER(spc_latin)                             AS latin_name,
    MAX(spc_common)                              AS common_name,
    COUNT(*)                                     AS total_2015,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 1 ELSE 0 END) AS dead_2015,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 0 ELSE 1 END) AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
)

/* ----------------------------------------------------------------------- */
SELECT
  y15.latin_name,
  y15.common_name,                     -- common name taken from 2015 data
  IFNULL(t95.total_1995,0)  AS total_1995,
  IFNULL(t95.alive_1995,0)  AS alive_1995,
  IFNULL(t95.dead_1995 ,0)  AS dead_1995,
  IFNULL(t05.total_2005,0)  AS total_2005,
  IFNULL(t05.alive_2005,0)  AS alive_2005,
  IFNULL(t05.dead_2005 ,0)  AS dead_2005,
  y15.total_2015,
  y15.alive_2015,
  y15.dead_2015,
  /* growth from 1995 to 2015 -------------------------------------------- */
  (y15.total_2015 - IFNULL(t95.total_1995,0)) AS growth_total_95_15,
  (y15.alive_2015 - IFNULL(t95.alive_1995,0)) AS growth_alive_95_15,
  (y15.dead_2015  - IFNULL(t95.dead_1995 ,0)) AS growth_dead_95_15
FROM yr2015 y15
LEFT JOIN yr1995 t95 USING(latin_name)
LEFT JOIN yr2005 t05 USING(latin_name)
ORDER BY growth_total_95_15 DESC
LIMIT 10;