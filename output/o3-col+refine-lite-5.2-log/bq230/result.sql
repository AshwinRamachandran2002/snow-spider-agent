-- Total 2022 state‑level production totals (corn in bushels & mushrooms)
WITH corn AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_prod_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND commodity_desc      = 'CORN'
    AND group_desc          = 'FIELD CROPS'
    AND statisticcat_desc   = 'PRODUCTION'
    AND agg_level_desc      = 'STATE'
    AND unit_desc           = 'BU'          -- bushels
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),
mushrooms AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushroom_prod
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND commodity_desc      = 'MUSHROOMS'
    AND group_desc          = 'HORTICULTURE'
    AND statisticcat_desc   = 'PRODUCTION'
    AND agg_level_desc      = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
)
SELECT
  COALESCE(c.state_name, m.state_name) AS state_name,
  c.corn_prod_bu,
  m.mushroom_prod
FROM corn      AS c
FULL OUTER JOIN mushrooms AS m
ON c.state_alpha = m.state_alpha
ORDER BY state_name;