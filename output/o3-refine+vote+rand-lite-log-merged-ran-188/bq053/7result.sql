-- Change in the number of living NYC trees by fall-color group, 1995 → 2015
WITH living_1995 AS (
  SELECT
    UPPER(spc_latin) AS species_uc,
    COUNT(*)         AS cnt_1995_living
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) NOT IN ('DEAD','STUMP')
  GROUP BY species_uc
),
alive_2015 AS (
  SELECT
    UPPER(spc_latin) AS species_uc,
    COUNT(*)         AS cnt_2015_alive
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'
  GROUP BY species_uc
)
SELECT
  ts.fall_color,
  SUM( COALESCE(a15.cnt_2015_alive,0)
      - COALESCE(l95.cnt_1995_living,0) ) AS total_change_1995_to_2015
FROM `bigquery-public-data.new_york.tree_species` AS ts
LEFT JOIN living_1995 AS l95
  ON UPPER(ts.species_scientific_name) = l95.species_uc
LEFT JOIN alive_2015  AS a15
  ON UPPER(ts.species_scientific_name) = a15.species_uc
GROUP BY ts.fall_color
ORDER BY total_change_1995_to_2015 DESC;