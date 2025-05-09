-- Top‑10 NYC tree species (Latin names upper‑cased) ranked by change in total
-- census counts from 1995 to 2015, with alive / dead details for every census year
WITH census AS (
  SELECT
    UPPER(spc_latin)                                AS latin_name,
    spc_common                                      AS common_name,
    CAST(_TABLE_SUFFIX AS INT64)                    AS yr,
    COUNT(*)                                        AS total_cnt,
    -- very liberal “alive” bucket so that 1995 (‘Good’, ‘Poor’, …) maps to ALIVE
    SUM(
      CASE
        WHEN LOWER(status) LIKE '%dead%'  THEN 0       -- dead
        WHEN LOWER(status) LIKE '%stump%' THEN 0       -- dead
        ELSE 1                                         -- treat the rest as alive
      END
    )                                                AS alive_cnt,
    SUM(
      CASE
        WHEN LOWER(status) LIKE '%dead%'  THEN 1
        WHEN LOWER(status) LIKE '%stump%' THEN 1
        ELSE 0
      END
    )                                                AS dead_cnt
  FROM `bigquery-public-data.new_york.tree_census_*`
  WHERE _TABLE_SUFFIX IN ('1995','2005','2015')   -- only census years available
        AND spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name, common_name, yr
),

pivot AS (
  SELECT
    latin_name,
    common_name,

    MAX(IF(yr = 1995, total_cnt, NULL)) AS total_1995,
    MAX(IF(yr = 1995, alive_cnt, NULL)) AS alive_1995,
    MAX(IF(yr = 1995, dead_cnt , NULL)) AS dead_1995,

    MAX(IF(yr = 2005, total_cnt, NULL)) AS total_2005,
    MAX(IF(yr = 2005, alive_cnt, NULL)) AS alive_2005,
    MAX(IF(yr = 2005, dead_cnt , NULL)) AS dead_2005,

    MAX(IF(yr = 2015, total_cnt, NULL)) AS total_2015,
    MAX(IF(yr = 2015, alive_cnt, NULL)) AS alive_2015,
    MAX(IF(yr = 2015, dead_cnt , NULL)) AS dead_2015
  FROM census
  GROUP BY latin_name, common_name
)

SELECT
  latin_name                              AS latin_name_upper,
  common_name,

  IFNULL(total_1995,0)                    AS total_1995,
  IFNULL(alive_1995,0)                    AS alive_1995,
  IFNULL(dead_1995 ,0)                    AS dead_1995,

  IFNULL(total_2005,0)                    AS total_2005,
  IFNULL(alive_2005,0)                    AS alive_2005,
  IFNULL(dead_2005 ,0)                    AS dead_2005,

  IFNULL(total_2015,0)                    AS total_2015,
  IFNULL(alive_2015,0)                    AS alive_2015,
  IFNULL(dead_2015 ,0)                    AS dead_2015,

  IFNULL(total_2015,0) - IFNULL(total_1995,0) AS total_growth_1995_2015,
  IFNULL(alive_2015,0) - IFNULL(alive_1995,0) AS alive_growth_1995_2015,
  IFNULL(dead_2015 ,0) - IFNULL(dead_1995 ,0) AS dead_growth_1995_2015

FROM pivot
ORDER BY total_growth_1995_2015 DESC
LIMIT 10;