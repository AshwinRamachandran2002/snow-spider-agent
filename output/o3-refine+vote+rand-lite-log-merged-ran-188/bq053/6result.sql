WITH living_1995 AS (
  -- # of trees not marked as dead in 1995, by species
  SELECT
    UPPER(spc_latin) AS species_key,
    COUNT(*)         AS living_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL
    AND LOWER(status) NOT LIKE '%dead%'            -- exclude rows whose status contains “dead”
  GROUP BY species_key
),
living_2015 AS (
  -- # of alive trees in 2015, by species
  SELECT
    UPPER(spc_latin) AS species_key,
    COUNT(*)         AS living_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL
    AND LOWER(status) = 'alive'                    -- keep only living trees
  GROUP BY species_key
),
species_delta AS (
  -- attach fall-color and compute change per species
  SELECT
    ts.fall_color,
    COALESCE(l15.living_2015, 0) - COALESCE(l95.living_1995, 0) AS net_change
  FROM `bigquery-public-data.new_york.tree_species` AS ts
  LEFT JOIN living_1995 AS l95
    ON UPPER(ts.species_scientific_name) = l95.species_key
  LEFT JOIN living_2015 AS l15
    ON UPPER(ts.species_scientific_name) = l15.species_key
)
-- final aggregation: change in living-tree counts by fall color
SELECT
  fall_color,
  SUM(net_change) AS total_net_change_1995_to_2015
FROM species_delta
GROUP BY fall_color
ORDER BY total_net_change_1995_to_2015 DESC;