WITH species_alive_2015 AS (
  SELECT DISTINCT LOWER(tc15.spc_latin) AS species_name
  FROM `bigquery-public-data.new_york.tree_census_2015` AS tc15
  WHERE tc15.status = 'Alive' AND tc15.spc_latin IS NOT NULL
),
alive_trees_1995 AS (
  SELECT
    ts.fall_color AS Fall_Color,
    COUNT(*) AS Trees_in_1995
  FROM `bigquery-public-data.new_york.tree_census_1995` AS tc95
  JOIN species_alive_2015 AS sa15
    ON LOWER(tc95.spc_latin) = sa15.species_name
  JOIN `bigquery-public-data.new_york.tree_species` AS ts
    ON LOWER(tc95.spc_latin) = LOWER(ts.species_scientific_name)
  WHERE tc95.status NOT IN ('Dead', 'Stump', 'Planting Space', 'Unknown')
  GROUP BY ts.fall_color
),
alive_trees_2015 AS (
  SELECT
    ts.fall_color AS Fall_Color,
    COUNT(*) AS Trees_in_2015
  FROM `bigquery-public-data.new_york.tree_census_2015` AS tc15
  JOIN `bigquery-public-data.new_york.tree_species` AS ts
    ON LOWER(tc15.spc_latin) = LOWER(ts.species_scientific_name)
  WHERE tc15.status = 'Alive' AND tc15.spc_latin IS NOT NULL
  GROUP BY ts.fall_color
)
SELECT
  COALESCE(alive_trees_1995.Fall_Color, alive_trees_2015.Fall_Color) AS Fall_Color,
  alive_trees_1995.Trees_in_1995,
  alive_trees_2015.Trees_in_2015
FROM alive_trees_1995
FULL OUTER JOIN alive_trees_2015
  ON alive_trees_1995.Fall_Color = alive_trees_2015.Fall_Color
ORDER BY Fall_Color;