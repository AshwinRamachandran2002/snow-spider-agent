-- Change in the number of *living* trees per Fall-color from 1995 → 2015
WITH live_1995 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species,
    COUNT(*)               AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL           -- keep only identified species
    AND UPPER(status) <> 'DEAD'         -- treat everything but “Dead” as living
  GROUP BY species
),
live_2015 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species,
    COUNT(*)               AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND UPPER(status) = 'ALIVE'         -- only trees explicitly marked Alive
  GROUP BY species
),
species_delta AS (                       -- Δ = living-1995  −  alive-2015
  SELECT
    COALESCE(l95.species, l15.species)          AS species,
    COALESCE(l95.cnt_1995, 0)
      - COALESCE(l15.cnt_2015, 0)               AS delta_count
  FROM live_1995 l95
  FULL JOIN live_2015 l15 USING (species)
)
SELECT
  ts.fall_color,
  SUM(sd.delta_count) AS change_in_tree_count
FROM species_delta sd
JOIN `bigquery-public-data.new_york.tree_species` ts
  ON UPPER(ts.species_scientific_name) = sd.species
GROUP BY ts.fall_color
ORDER BY change_in_tree_count DESC;