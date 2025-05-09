-- change in the number of living trees by fall color from 1995 to 2015
WITH

-- 1995 census: trees whose status is NOT Dead
living_1995 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*)        AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE UPPER(status) != 'DEAD'
  GROUP BY species
),

-- 2015 census: trees whose status is Alive
alive_2015 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*)         AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(status) = 'ALIVE'
  GROUP BY species
),

-- reference table mapping species to fall color
species_colors AS (
  SELECT
    UPPER(species_scientific_name) AS species,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
),

-- combine counts for each species and compute the change
species_change AS (
  SELECT
    sc.fall_color,
    COALESCE(a.cnt_2015, 0)  AS alive_2015,
    COALESCE(l.cnt_1995, 0)  AS living_1995,
    COALESCE(a.cnt_2015, 0) - COALESCE(l.cnt_1995, 0) AS change_in_count
  FROM species_colors sc
  LEFT JOIN alive_2015 a  ON sc.species = a.species
  LEFT JOIN living_1995 l ON sc.species = l.species
)

-- sum changes by fall color
SELECT
  fall_color,
  SUM(change_in_count) AS total_change_in_trees
FROM species_change
GROUP BY fall_color
ORDER BY total_change_in_trees DESC;