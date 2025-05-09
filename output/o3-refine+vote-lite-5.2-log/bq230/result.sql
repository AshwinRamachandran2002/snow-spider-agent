-- Corn (bushels) and Mushroom production totals by state for 2022
WITH corn AS (
  SELECT
    state_name,
    SUM(value) AS corn_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND agg_level_desc = 'STATE'
    AND statisticcat_desc = 'PRODUCTION'
    AND group_desc = 'FIELD CROPS'
    AND commodity_desc = 'CORN'
    AND unit_desc = 'BU'          -- ensure corn measured in bushels
    AND value IS NOT NULL
  GROUP BY state_name
),
mushrooms AS (
  SELECT
    state_name,
    SUM(value) AS mushrooms_total
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND agg_level_desc = 'STATE'
    AND statisticcat_desc = 'PRODUCTION'
    AND group_desc = 'HORTICULTURE'
    AND commodity_desc = 'MUSHROOMS'
    AND value IS NOT NULL
  GROUP BY state_name
)

SELECT
  COALESCE(c.state_name, m.state_name) AS state_name,
  c.corn_bu,
  m.mushrooms_total
FROM corn AS c
FULL OUTER JOIN mushrooms AS m
ON c.state_name = m.state_name
ORDER BY state_name;