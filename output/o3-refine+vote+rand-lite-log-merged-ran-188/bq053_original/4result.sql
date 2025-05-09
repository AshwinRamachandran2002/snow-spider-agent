-- Change in the number of living NYC street trees (2015 − 1995)  
-- aggregated by the FALL COLOR category of each species
WITH
-- 1995: trees that were *not* recorded as dead
cnt_1995 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species_name,
    COUNT(*)               AS n_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE COALESCE(UPPER(TRIM(status)), '') <> 'DEAD'
  GROUP BY species_name
),

-- 2015: trees recorded as ALIVE
cnt_2015 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species_name,
    COUNT(*)               AS n_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE UPPER(TRIM(status)) = 'ALIVE'
  GROUP BY species_name
),

-- per‑species change (2015 − 1995)
delta_per_species AS (
  SELECT
    COALESCE(c15.species_name, c95.species_name)      AS species_name,
    IFNULL(c15.n_2015, 0) - IFNULL(c95.n_1995, 0)     AS change_in_count
  FROM cnt_1995 c95
  FULL OUTER JOIN cnt_2015 c15
  ON c95.species_name = c15.species_name
),

-- map each species to its fall color
species_color AS (
  SELECT
    UPPER(TRIM(species_scientific_name)) AS species_name,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
  WHERE fall_color IS NOT NULL
)

-- final aggregation by fall color
SELECT
  sc.fall_color,
  SUM(dps.change_in_count) AS total_change_in_trees
FROM delta_per_species dps
JOIN species_color sc
ON dps.species_name = sc.species_name
GROUP BY sc.fall_color
ORDER BY total_change_in_trees DESC;