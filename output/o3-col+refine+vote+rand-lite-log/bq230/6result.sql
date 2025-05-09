-- 2022 state-level production totals: corn (bushels) & mushrooms (reported unit, mainly pounds)
WITH corn AS (
  SELECT
    state_name,
    SUM(value) AS corn_bushels
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year                = 2022
    AND commodity_desc      = 'CORN'
    AND group_desc          = 'FIELD CROPS'
    AND statisticcat_desc   = 'PRODUCTION'
    AND agg_level_desc      = 'STATE'
    AND unit_desc           = 'BU'          -- bushels
    AND value IS NOT NULL
  GROUP BY state_name
),
mushrooms AS (
  SELECT
    state_name,
    SUM(value)            AS mushroom_qty,
    ANY_VALUE(unit_desc)  AS mushroom_unit  -- typically “LB”
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year                = 2022
    AND commodity_desc      = 'MUSHROOMS'
    AND group_desc          = 'HORTICULTURE'
    AND statisticcat_desc   = 'PRODUCTION'
    AND agg_level_desc      = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_name
)
SELECT
  COALESCE(c.state_name, m.state_name) AS state_name,
  c.corn_bushels,
  m.mushroom_qty,
  m.mushroom_unit
FROM corn AS c
FULL OUTER JOIN mushrooms AS m
USING (state_name)
ORDER BY state_name;