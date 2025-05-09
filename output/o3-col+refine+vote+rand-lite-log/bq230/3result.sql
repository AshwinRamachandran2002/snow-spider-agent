-- 2022 state-level production totals:
--    • Corn (bushels) from FIELD CROPS
--    • Mushrooms (any unit – typically pounds) from HORTICULTURE
WITH corn AS (
  SELECT
    state_alpha AS state,
    SUM(value) AS corn_bu_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year               = 2022
    AND group_desc         = 'FIELD CROPS'
    AND commodity_desc     = 'CORN'
    AND statisticcat_desc  = 'PRODUCTION'
    AND agg_level_desc     = 'STATE'
    AND unit_desc          = 'BU'          -- bushels
    AND value IS NOT NULL
  GROUP BY state
),
mushrooms AS (
  SELECT
    state_alpha AS state,
    SUM(value) AS mushroom_prod_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year               = 2022
    AND group_desc         = 'HORTICULTURE'
    AND LOWER(commodity_desc) LIKE '%mushroom%'
    AND statisticcat_desc  = 'PRODUCTION'
    AND agg_level_desc     = 'STATE'
    AND value IS NOT NULL
  GROUP BY state
)

SELECT
  COALESCE(c.state, m.state) AS state,
  c.corn_bu_2022,
  m.mushroom_prod_2022
FROM corn AS c
FULL OUTER JOIN mushrooms AS m
ON c.state = m.state
ORDER BY state;