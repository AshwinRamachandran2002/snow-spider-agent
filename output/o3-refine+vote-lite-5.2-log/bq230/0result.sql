WITH corn_2022 AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND agg_level_desc = 'STATE'
    AND statisticcat_desc = 'PRODUCTION'
    AND group_desc = 'FIELD CROPS'
    AND commodity_desc = 'CORN'
    AND unit_desc = 'BU'          -- ensure bushels
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),
mushroom_2022 AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushroom_production
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND agg_level_desc = 'STATE'
    AND statisticcat_desc = 'PRODUCTION'
    AND group_desc = 'HORTICULTURE'
    AND commodity_desc = 'MUSHROOMS'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
)
SELECT
  COALESCE(c.state_name, m.state_name)   AS state_name,
  COALESCE(c.state_alpha, m.state_alpha) AS state_abbr,
  c.corn_production_bu,                  -- 2022 corn production (bushels)
  m.mushroom_production                  -- 2022 mushroom production (original units)
FROM corn_2022 AS c
FULL OUTER JOIN mushroom_2022 AS m
ON c.state_alpha = m.state_alpha
ORDER BY state_name;