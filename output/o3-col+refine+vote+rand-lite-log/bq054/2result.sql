-- Top 10 species by change in total count between the 1995 and 2015 NYC street-tree censuses
WITH yr1995 AS (
  SELECT
    UPPER(spc_latin)                                          AS latin,
    COUNT(*)                                                  AS total_1995,
    SUM(CASE WHEN UPPER(status) IN ('DEAD','STUMP','SHAFT')
             THEN 1 ELSE 0 END)                              AS dead_1995,
    SUM(CASE WHEN UPPER(status) NOT IN ('DEAD','STUMP','SHAFT')
             THEN 1 ELSE 0 END)                              AS alive_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND TRIM(spc_latin) <> ''
  GROUP BY latin
),
yr2015 AS (
  SELECT
    UPPER(spc_latin)                                          AS latin,
    COUNT(*)                                                  AS total_2015,
    SUM(CASE WHEN UPPER(status) IN ('DEAD','STUMP')
             THEN 1 ELSE 0 END)                              AS dead_2015,
    SUM(CASE WHEN UPPER(status) = 'ALIVE'
             THEN 1 ELSE 0 END)                              AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND TRIM(spc_latin) <> ''
  GROUP BY latin
),
joined AS (
  SELECT
    COALESCE(y15.latin, y95.latin)                           AS latin,
    y95.total_1995, y95.alive_1995, y95.dead_1995,
    y15.total_2015, y15.alive_2015, y15.dead_2015
  FROM yr1995 y95
  FULL JOIN yr2015 y15
  ON y15.latin = y95.latin
),
with_growth AS (
  SELECT
    latin,
    COALESCE(total_1995,0)      AS total_1995,
    COALESCE(alive_1995,0)      AS alive_1995,
    COALESCE(dead_1995,0)       AS dead_1995,
    COALESCE(total_2015,0)      AS total_2015,
    COALESCE(alive_2015,0)      AS alive_2015,
    COALESCE(dead_2015,0)       AS dead_2015,
    COALESCE(total_2015,0) - COALESCE(total_1995,0)  AS total_growth,
    COALESCE(alive_2015,0) - COALESCE(alive_1995,0)  AS alive_growth,
    COALESCE(dead_2015,0)  - COALESCE(dead_1995,0)   AS dead_growth
  FROM joined
)
SELECT
  wg.latin,
  ts.species_common_name                                       AS common_name,
  wg.total_1995, wg.alive_1995, wg.dead_1995,
  wg.total_2015, wg.alive_2015, wg.dead_2015,
  wg.total_growth, wg.alive_growth, wg.dead_growth
FROM with_growth wg
LEFT JOIN `bigquery-public-data.new_york.tree_species` ts
       ON UPPER(ts.species_scientific_name) = wg.latin
ORDER BY total_growth DESC
LIMIT 10;