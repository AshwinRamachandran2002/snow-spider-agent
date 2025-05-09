-- change in the number of living NYC trees by fall-color group (1995 ➜ 2015)
WITH
-- 1. 1995 trees that are NOT recorded as dead
cnt95 AS (
  SELECT
    UPPER(spc_latin) AS latin_name,
    COUNT(*)         AS not_dead_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) <> 'DEAD'
  GROUP BY latin_name
),

-- 2. 2015 trees that are recorded as ALIVE
cnt15 AS (
  SELECT
    UPPER(spc_latin) AS latin_name,
    COUNT(*)         AS alive_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'
  GROUP BY latin_name
),

-- 3. net change per species between the two censuses
species_change AS (
  SELECT
    COALESCE(c15.latin_name, c95.latin_name)                          AS latin_name,
    COALESCE(c15.alive_2015, 0) - COALESCE(c95.not_dead_1995, 0)     AS net_change
  FROM cnt95 AS c95
  FULL JOIN cnt15 AS c15
  ON c15.latin_name = c95.latin_name
)

-- 4. attach fall-color information and sum the change per color
SELECT
  ts.fall_color,
  SUM(sc.net_change) AS total_change_1995_to_2015
FROM species_change AS sc
LEFT JOIN `bigquery-public-data.new_york.tree_species` AS ts
  ON sc.latin_name = UPPER(ts.species_scientific_name)
GROUP BY ts.fall_color
ORDER BY total_change_1995_to_2015 DESC;