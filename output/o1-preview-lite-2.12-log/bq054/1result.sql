SELECT
  COALESCE(t95.spc_latin_std, t05.spc_latin_std, t15.spc_latin_std) AS Latin_Name,
  COALESCE(t95.spc_common, t05.spc_common, t15.spc_common) AS Common_Name,
  COALESCE(t95.total_trees_1995, 0) AS Total_Trees_1995,
  COALESCE(t95.alive_1995, 0) AS Alive_1995,
  COALESCE(t95.dead_1995, 0) AS Dead_1995,
  COALESCE(t05.alive_2005, 0) AS Alive_2005,
  COALESCE(t05.dead_2005, 0) AS Dead_2005,
  COALESCE(t15.alive_2015, 0) AS Alive_2015,
  COALESCE(t15.dead_2015, 0) AS Dead_2015,
  ((COALESCE(t15.alive_2015, 0) + COALESCE(t15.dead_2015, 0)) - 
   (COALESCE(t95.alive_1995, 0) + COALESCE(t95.dead_1995, 0))) AS Growth_in_Total_Trees
FROM
  -- Data from 1995
  (
    SELECT
      UPPER(TRIM(spc_latin)) AS spc_latin_std,
      MAX(UPPER(TRIM(spc_common))) AS spc_common,
      SUM(CASE WHEN LOWER(TRIM(status)) IN ('good', 'fair', 'poor', 'alive') THEN 1 ELSE 0 END) AS alive_1995,
      SUM(CASE WHEN LOWER(TRIM(status)) IN ('dead', 'stump') THEN 1 ELSE 0 END) AS dead_1995,
      COUNT(*) AS total_trees_1995
    FROM `bigquery-public-data.new_york.tree_census_1995`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    GROUP BY spc_latin_std
  ) t95
FULL OUTER JOIN
  -- Data from 2005
  (
    SELECT
      UPPER(TRIM(spc_latin)) AS spc_latin_std,
      MAX(UPPER(TRIM(spc_common))) AS spc_common,
      SUM(CASE WHEN LOWER(TRIM(status)) IN ('excellent', 'good', 'fair', 'poor', 'alive') THEN 1 ELSE 0 END) AS alive_2005,
      SUM(CASE WHEN LOWER(TRIM(status)) IN ('dead', 'stump', 'dead stump') THEN 1 ELSE 0 END) AS dead_2005,
      COUNT(*) AS total_trees_2005
    FROM `bigquery-public-data.new_york.tree_census_2005`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    GROUP BY spc_latin_std
  ) t05
USING (spc_latin_std)
FULL OUTER JOIN
  -- Data from 2015
  (
    SELECT
      UPPER(TRIM(spc_latin)) AS spc_latin_std,
      MAX(UPPER(TRIM(spc_common))) AS spc_common,
      SUM(CASE WHEN LOWER(TRIM(status)) = 'alive' THEN 1 ELSE 0 END) AS alive_2015,
      SUM(CASE WHEN LOWER(TRIM(status)) IN ('dead', 'stump') THEN 1 ELSE 0 END) AS dead_2015,
      COUNT(*) AS total_trees_2015
    FROM `bigquery-public-data.new_york.tree_census_2015`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    GROUP BY spc_latin_std
  ) t15
USING (spc_latin_std)
WHERE COALESCE(t95.spc_latin_std, t05.spc_latin_std, t15.spc_latin_std) IS NOT NULL
ORDER BY Growth_in_Total_Trees DESC
LIMIT 10;