WITH census_1995 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*)         AS n1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND UPPER(status) <> 'DEAD'
  GROUP BY species
),
census_2015 AS (
  SELECT
    UPPER(spc_latin) AS species,
    COUNT(*)         AS n2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND UPPER(status) = 'ALIVE'
  GROUP BY species
),
species_diff AS (
  SELECT
    COALESCE(c15.species, c95.species) AS species,
    IFNULL(c15.n2015, 0) - IFNULL(c95.n1995, 0) AS delta
  FROM census_1995 c95
  FULL JOIN census_2015 c15
    ON c95.species = c15.species
),
diff_with_color AS (
  SELECT
    ts.fall_color,
    sd.delta
  FROM species_diff sd
  JOIN `bigquery-public-data.new_york.tree_species` ts
    ON UPPER(ts.species_scientific_name) = sd.species
)
SELECT
  fall_color,
  SUM(delta) AS total_change
FROM diff_with_color
GROUP BY fall_color
ORDER BY total_change DESC, fall_color;