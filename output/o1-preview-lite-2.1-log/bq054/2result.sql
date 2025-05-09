SELECT
  COALESCE(t2015.spc_latin, t1995.spc_latin) AS species_latin,
  IFNULL(t1995.count_total, 0) AS count_1995_total,
  IFNULL(t1995.count_alive, 0) AS count_1995_alive,
  IFNULL(t1995.count_dead, 0) AS count_1995_dead,
  IFNULL(t2015.count_total, 0) AS count_2015_total,
  IFNULL(t2015.count_alive, 0) AS count_2015_alive,
  IFNULL(t2015.count_dead, 0) AS count_2015_dead,
  (IFNULL(t2015.count_total, 0) - IFNULL(t1995.count_total, 0)) AS growth_total,
  (IFNULL(t2015.count_alive, 0) - IFNULL(t1995.count_alive, 0)) AS growth_alive,
  (IFNULL(t2015.count_dead, 0) - IFNULL(t1995.count_dead, 0)) AS growth_dead
FROM
  (
    SELECT
      UPPER(spc_latin) AS spc_latin,
      COUNT(*) AS count_total,
      SUM(CASE WHEN LOWER(status) IN ('good', 'fair', 'poor', 'excellent', 'critical') THEN 1 ELSE 0 END) AS count_alive,
      SUM(CASE WHEN LOWER(status) IN ('dead', 'stump', 'unknown', 'shaft', 'planting space') THEN 1 ELSE 0 END) AS count_dead
    FROM `bigquery-public-data.new_york.tree_census_1995`
    WHERE spc_latin IS NOT NULL AND spc_latin != ''
    GROUP BY UPPER(spc_latin)
  ) AS t1995
FULL OUTER JOIN
  (
    SELECT
      UPPER(spc_latin) AS spc_latin,
      COUNT(*) AS count_total,
      SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 ELSE 0 END) AS count_alive,
      SUM(CASE WHEN LOWER(status) = 'dead' THEN 1 ELSE 0 END) AS count_dead
    FROM `bigquery-public-data.new_york.tree_census_2015`
    WHERE spc_latin IS NOT NULL AND spc_latin != ''
    GROUP BY UPPER(spc_latin)
  ) AS t2015
ON t1995.spc_latin = t2015.spc_latin
WHERE COALESCE(t2015.spc_latin, t1995.spc_latin) IS NOT NULL
  AND COALESCE(t2015.spc_latin, t1995.spc_latin) != ''
ORDER BY growth_total DESC
LIMIT 10;