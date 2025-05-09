-- Change in the number of living trees by fall color (2015 vs. 1995)
WITH
/* 1995: trees that were NOT reported as dead */
census_1995 AS (
  SELECT
    UPPER(spc_latin)             AS species_upper,
    COUNT(*)                     AS cnt_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND LOWER(status) != 'dead'
  GROUP BY species_upper
),

/* 2015: trees that were explicitly reported as alive */
census_2015 AS (
  SELECT
    UPPER(spc_latin)             AS species_upper,
    COUNT(*)                     AS cnt_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND LOWER(status) = 'alive'
  GROUP BY species_upper
),

/* Combine counts for both years */
species_diff AS (
  SELECT
    COALESCE(c15.species_upper, c95.species_upper)      AS species_upper,
    IFNULL(c15.cnt_2015, 0)                             AS cnt_2015,
    IFNULL(c95.cnt_1995, 0)                             AS cnt_1995
  FROM census_2015 c15
  FULL JOIN census_1995 c95
  ON c15.species_upper = c95.species_upper
),

/* Map species to their fall color */
species_color AS (
  SELECT
    UPPER(species_scientific_name)  AS species_upper,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
)

/* Final aggregation: change in living trees per fall color */
SELECT
  COALESCE(sc.fall_color, 'Unknown')            AS fall_color,
  SUM(sd.cnt_2015 - sd.cnt_1995)                AS change_in_trees
FROM species_diff sd
LEFT JOIN species_color sc
  ON sd.species_upper = sc.species_upper
GROUP BY fall_color
ORDER BY change_in_trees DESC;