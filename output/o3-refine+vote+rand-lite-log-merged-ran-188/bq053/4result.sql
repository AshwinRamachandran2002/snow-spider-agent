WITH cnt_1995 AS (
  -- trees inventoried in 1995 whose status is NOT 'Dead'
  SELECT
    UPPER(spc_latin)          AS sci_name,
    COUNT(*)                  AS live_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND UPPER(status) <> 'DEAD'
  GROUP BY sci_name
),
cnt_2015 AS (
  -- trees inventoried in 2015 whose status is exactly 'Alive'
  SELECT
    UPPER(spc_latin)          AS sci_name,
    COUNT(*)                  AS live_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND LOWER(status) = 'alive'
  GROUP BY sci_name
)

SELECT
  COALESCE(ts.fall_color, 'Unknown') AS fall_color,
  SUM( COALESCE(c15.live_2015,0) - COALESCE(c95.live_1995,0) )
      AS change_in_living_trees_1995_to_2015
FROM `bigquery-public-data.new_york.tree_species` ts
LEFT JOIN cnt_1995 c95
  ON UPPER(ts.species_scientific_name) = c95.sci_name
LEFT JOIN cnt_2015 c15
  ON UPPER(ts.species_scientific_name) = c15.sci_name
GROUP BY fall_color
ORDER BY change_in_living_trees_1995_to_2015 DESC;