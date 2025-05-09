-- Change in the number of living trees (2015 – 1995) by fall color
WITH species_map AS (
  SELECT
    UPPER(species_scientific_name) AS species_name,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
),
cnt_1995 AS (        -- trees that were NOT dead in 1995
  SELECT
    UPPER(spc_latin) AS species_name,
    COUNT(*)          AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) NOT IN ('DEAD', 'DEAD STANDING', 'STUMP', 'REMOVED')
  GROUP BY species_name
),
cnt_2015 AS (        -- trees that were ALIVE in 2015
  SELECT
    UPPER(spc_latin) AS species_name,
    COUNT(*)          AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'
  GROUP BY species_name
),
species_change AS (  -- difference per species
  SELECT
    sm.fall_color,
    COALESCE(c15.cnt_2015, 0) - COALESCE(c95.cnt_1995, 0) AS change_count
  FROM species_map sm
  LEFT JOIN cnt_1995 c95 USING (species_name)
  LEFT JOIN cnt_2015 c15 USING (species_name)
)
SELECT
  fall_color,
  SUM(change_count) AS total_change_in_trees
FROM species_change
GROUP BY fall_color
ORDER BY total_change_in_trees DESC;