-- Top-10 tree species by increase in total count (1995 → 2015)
WITH census AS (
  -- 1995
  SELECT
    UPPER(spc_latin)                          AS latin,
    '1995'                                    AS yr,
    CASE WHEN UPPER(status) LIKE '%DEAD%'     THEN 'dead' ELSE 'alive' END AS life
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''

  UNION ALL
  -- 2005
  SELECT
    UPPER(spc_latin),
    '2005',
    CASE WHEN UPPER(status) LIKE '%DEAD%'     THEN 'dead' ELSE 'alive' END
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''

  UNION ALL
  -- 2015
  SELECT
    UPPER(spc_latin),
    '2015',
    CASE WHEN UPPER(status) LIKE '%DEAD%'     THEN 'dead' ELSE 'alive' END
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
),

agg AS (
  SELECT
    latin,
    -- 1995 counts
    SUM(CASE WHEN yr='1995' THEN 1 END)                                  AS total_1995,
    SUM(CASE WHEN yr='1995' AND life='alive' THEN 1 END)                 AS alive_1995,
    SUM(CASE WHEN yr='1995' AND life='dead'  THEN 1 END)                 AS dead_1995,
    -- 2005 counts
    SUM(CASE WHEN yr='2005' THEN 1 END)                                  AS total_2005,
    SUM(CASE WHEN yr='2005' AND life='alive' THEN 1 END)                 AS alive_2005,
    SUM(CASE WHEN yr='2005' AND life='dead'  THEN 1 END)                 AS dead_2005,
    -- 2015 counts
    SUM(CASE WHEN yr='2015' THEN 1 END)                                  AS total_2015,
    SUM(CASE WHEN yr='2015' AND life='alive' THEN 1 END)                 AS alive_2015,
    SUM(CASE WHEN yr='2015' AND life='dead'  THEN 1 END)                 AS dead_2015
  FROM census
  GROUP BY latin
),

with_common AS (
  SELECT
    a.*,
    ts.species_common_name                                                  AS common_name,
    total_2015 - total_1995                                                 AS growth_total,
    alive_2015 - alive_1995                                                 AS growth_alive,
    dead_2015  - dead_1995                                                  AS growth_dead
  FROM agg a
  LEFT JOIN `bigquery-public-data.new_york.tree_species` ts
         ON UPPER(ts.species_scientific_name) = a.latin
)

SELECT
  latin                               AS spc_latin_upper,
  common_name,
  total_1995, alive_1995, dead_1995,
  total_2005, alive_2005, dead_2005,
  total_2015, alive_2015, dead_2015,
  growth_total, growth_alive, growth_dead
FROM with_common
ORDER BY growth_total DESC
LIMIT 10;