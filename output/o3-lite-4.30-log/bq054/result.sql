WITH
-- 1995 tree census aggregated by species
c1995 AS (
  SELECT
    UPPER(spc_latin)                                   AS latin_name,
    ANY_VALUE(spc_common)                              AS common_name,
    COUNT(*)                                           AS total_1995,
    COUNTIF(LOWER(status) = 'dead')                    AS dead_1995,
    COUNTIF(LOWER(status) NOT IN ('dead','stump'))     AS alive_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
  GROUP BY latin_name
),
-- 2015 tree census aggregated by species
c2015 AS (
  SELECT
    UPPER(spc_latin)                                   AS latin_name,
    ANY_VALUE(spc_common)                              AS common_name,
    COUNT(*)                                           AS total_2015,
    COUNTIF(LOWER(status) = 'dead')                    AS dead_2015,
    COUNTIF(LOWER(status) = 'alive')                   AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
  GROUP BY latin_name
),
-- merge the two years, replacing NULLs with 0 for arithmetic
merged AS (
  SELECT
    COALESCE(c2015.latin_name, c1995.latin_name) AS latin_name,
    COALESCE(c2015.common_name, c1995.common_name) AS common_name,
    IFNULL(total_1995, 0)   AS total_1995,
    IFNULL(total_2015, 0)   AS total_2015,
    IFNULL(alive_1995, 0)   AS alive_1995,
    IFNULL(alive_2015, 0)   AS alive_2015,
    IFNULL(dead_1995, 0)    AS dead_1995,
    IFNULL(dead_2015, 0)    AS dead_2015
  FROM c1995
  FULL JOIN c2015 USING (latin_name)
)
-- final selection & growth calculations
SELECT
  latin_name,
  common_name,
  total_1995,
  total_2015,
  total_2015 - total_1995           AS growth_total,
  alive_1995,
  alive_2015,
  alive_2015 - alive_1995           AS growth_alive,
  dead_1995,
  dead_2015,
  dead_2015  - dead_1995            AS growth_dead
FROM merged
WHERE latin_name IS NOT NULL
ORDER BY growth_total DESC, latin_name
LIMIT 10;