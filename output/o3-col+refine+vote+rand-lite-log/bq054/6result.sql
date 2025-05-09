WITH
-- 1995 census: totals + alive / dead split
c1995 AS (
  SELECT
    UPPER(spc_latin)                                   AS latin_name,
    ANY_VALUE(spc_common)                              AS common_name_1995,
    COUNT(*)                                           AS total_1995,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 1 ELSE 0 END) AS dead_1995,
    SUM(CASE WHEN LOWER(status) LIKE '%dead%' THEN 0 ELSE 1 END) AS alive_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
),

-- 2015 census: totals + alive / dead split
c2015 AS (
  SELECT
    UPPER(spc_latin)                                   AS latin_name,
    ANY_VALUE(spc_common)                              AS common_name_2015,
    COUNT(*)                                           AS total_2015,
    SUM(CASE WHEN LOWER(status) = 'dead'  THEN 1 ELSE 0 END) AS dead_2015,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 ELSE 0 END) AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY latin_name
)

SELECT
  c2015.latin_name                                               AS latin_name_uppercase,
  COALESCE(c2015.common_name_2015, c1995.common_name_1995)       AS common_name,
  c1995.total_1995,
  c1995.alive_1995,
  c1995.dead_1995,
  c2015.total_2015,
  c2015.alive_2015,
  c2015.dead_2015,
  c2015.total_2015  - c1995.total_1995  AS growth_total,
  c2015.alive_2015  - c1995.alive_1995  AS growth_alive,
  c2015.dead_2015   - c1995.dead_1995   AS growth_dead
FROM c2015
JOIN c1995 USING (latin_name)        -- keep species present in both years
ORDER BY growth_total DESC
LIMIT 10;