-- Top-10 tree species: change from 1995 to 2015
WITH
/* ---------- 1995 census aggregated by scientific (Latin) name ---------- */
census_1995 AS (
  SELECT
    UPPER(spc_latin)                                       AS latin_name,
    COUNT(*)                                               AS total_1995,
    SUM(CASE WHEN LOWER(status) LIKE 'dead%' THEN 1 ELSE 0 END) AS dead_1995,
    COUNT(*) - SUM(CASE WHEN LOWER(status) LIKE 'dead%' THEN 1 ELSE 0 END) AS alive_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
    AND UPPER(spc_latin) <> 'UNKNOWN'
  GROUP BY latin_name
),

/* ---------- 2015 census aggregated by the same Latin name ---------- */
census_2015 AS (
  SELECT
    UPPER(spc_latin)                                       AS latin_name,
    ANY_VALUE(spc_common)                                  AS common_name,   -- keep a readable common name
    COUNT(*)                                               AS total_2015,
    SUM(CASE WHEN LOWER(status) = 'dead' THEN 1 ELSE 0 END) AS dead_2015,
    COUNT(*) - SUM(CASE WHEN LOWER(status) = 'dead' THEN 1 ELSE 0 END) AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
    AND UPPER(spc_latin) <> 'UNKNOWN'
  GROUP BY latin_name
)

/* ---------- Combine yearly stats & compute growth ---------- */
SELECT
  c15.latin_name,
  c15.common_name,
  total_1995,
  alive_1995,
  dead_1995,
  total_2015,
  alive_2015,
  dead_2015,
  (total_2015  - total_1995)  AS growth_total,
  (alive_2015  - alive_1995)  AS growth_alive,
  (dead_2015   - dead_1995)   AS growth_dead
FROM census_1995 c95
JOIN census_2015 c15 USING (latin_name)
ORDER BY growth_total DESC
LIMIT 10;