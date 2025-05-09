WITH counts_1995 AS (
  SELECT 
    UPPER(TRIM(spc_latin)) AS species_latin,
    COUNT(*) AS count_1995_total,
    COUNT(*) - SUM(CASE WHEN LOWER(status) IN ('dead', 'stump') THEN 1 ELSE 0 END) AS count_1995_alive,
    SUM(CASE WHEN LOWER(status) IN ('dead', 'stump') THEN 1 ELSE 0 END) AS count_1995_dead
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
  GROUP BY species_latin
),
counts_2015 AS (
  SELECT 
    UPPER(TRIM(spc_latin)) AS species_latin,
    COUNT(*) AS count_2015_total,
    COUNT(*) - SUM(CASE WHEN LOWER(status) IN ('dead', 'stump', 'dead stump') THEN 1 ELSE 0 END) AS count_2015_alive,
    SUM(CASE WHEN LOWER(status) IN ('dead', 'stump', 'dead stump') THEN 1 ELSE 0 END) AS count_2015_dead
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
  GROUP BY species_latin
)

SELECT
  COALESCE(c2015.species_latin, c1995.species_latin) AS species_latin,
  IFNULL(c1995.count_1995_total, 0) AS count_1995_total,
  IFNULL(c1995.count_1995_alive, 0) AS count_1995_alive,
  IFNULL(c1995.count_1995_dead, 0) AS count_1995_dead,
  IFNULL(c2015.count_2015_total, 0) AS count_2015_total,
  IFNULL(c2015.count_2015_alive, 0) AS count_2015_alive,
  IFNULL(c2015.count_2015_dead, 0) AS count_2015_dead,
  IFNULL(c2015.count_2015_total, 0) - IFNULL(c1995.count_1995_total, 0) AS growth_total,
  IFNULL(c2015.count_2015_alive, 0) - IFNULL(c1995.count_1995_alive, 0) AS growth_alive,
  IFNULL(c2015.count_2015_dead, 0) - IFNULL(c1995.count_1995_dead, 0) AS growth_dead
FROM counts_2015 c2015
FULL OUTER JOIN counts_1995 c1995
  ON c2015.species_latin = c1995.species_latin
WHERE COALESCE(c2015.species_latin, c1995.species_latin) IS NOT NULL
  AND COALESCE(c2015.species_latin, c1995.species_latin) != ''
ORDER BY growth_total DESC
LIMIT 10;