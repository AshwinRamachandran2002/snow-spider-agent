WITH corn AS (
  SELECT
    state_name,
    SUM(value) AS corn_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
    year = 2022
    AND sector_desc = 'CROPS'
    AND group_desc = 'FIELD CROPS'
    AND commodity_desc = 'CORN'
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc = 'STATE'
    AND unit_desc = 'BU'          -- bushels
    AND value IS NOT NULL
  GROUP BY state_name
),
mushrooms AS (
  SELECT
    state_name,
    SUM(value) AS mushroom_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
    year = 2022
    AND sector_desc = 'CROPS'
    AND group_desc = 'HORTICULTURE'
    AND commodity_desc = 'MUSHROOMS'
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc = 'STATE'
    AND unit_desc = 'BU'          -- bushels
    AND value IS NOT NULL
  GROUP BY state_name
)

SELECT
  COALESCE(c.state_name, m.state_name) AS state_name,
  c.corn_bu,
  m.mushroom_bu
FROM corn c
FULL OUTER JOIN mushrooms m
ON c.state_name = m.state_name
ORDER BY state_name;