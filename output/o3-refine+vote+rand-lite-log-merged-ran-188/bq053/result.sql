-- Calculate the change in living-tree counts by fall-color between 1995 and 2015
WITH
-- 1995 trees that are NOT marked as dead
t95 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species_name,
    COUNT(*)               AS trees_1995_not_dead
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
    AND (status IS NULL OR UPPER(status) <> 'DEAD')
  GROUP BY species_name
),

-- 2015 trees that are ALIVE
t15 AS (
  SELECT
    UPPER(TRIM(spc_latin)) AS species_name,
    COUNT(*)               AS trees_2015_alive
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND spc_latin <> ''
    AND UPPER(status) = 'ALIVE'
  GROUP BY species_name
),

-- Per-species change from 1995 to 2015
diff AS (
  SELECT
    COALESCE(t15.species_name, t95.species_name) AS species_name,
    COALESCE(t15.trees_2015_alive, 0) -
    COALESCE(t95.trees_1995_not_dead, 0)         AS change_in_count
  FROM t95
  FULL OUTER JOIN t15
  ON t95.species_name = t15.species_name
),

-- Map species to their fall color
color_map AS (
  SELECT
    UPPER(TRIM(species_scientific_name)) AS species_name,
    fall_color
  FROM `bigquery-public-data.new_york.tree_species`
  WHERE fall_color IS NOT NULL
    AND fall_color <> ''
)

-- Aggregate the changes by fall color
SELECT
  color_map.fall_color,
  SUM(diff.change_in_count) AS total_change_in_trees
FROM diff
JOIN color_map
ON diff.species_name = color_map.species_name
GROUP BY color_map.fall_color
ORDER BY total_change_in_trees DESC;