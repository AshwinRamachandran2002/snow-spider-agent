WITH corn AS (
  SELECT
    state_alpha AS state,
    SUM(value) AS corn_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc   = 'STATE'
    AND group_desc       = 'FIELD CROPS'
    AND commodity_desc   = 'CORN'
    AND unit_desc        = 'BU'          -- bushels
    AND domain_desc      = 'TOTAL'       -- avoid duplicate breakouts
    AND value IS NOT NULL
    AND state_alpha NOT IN ('OT')        -- exclude “OTHER STATES”
  GROUP BY state_alpha
),
mushrooms AS (
  SELECT
    state_alpha AS state,
    SUM(value) AS mushroom_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc   = 'STATE'
    AND group_desc       = 'HORTICULTURE'
    AND commodity_desc   = 'MUSHROOMS'
    AND domain_desc      = 'TOTAL'
    AND value IS NOT NULL
    AND state_alpha NOT IN ('OT')        -- exclude “OTHER STATES”
  GROUP BY state_alpha
)
SELECT
  COALESCE(c.state, m.state)                      AS state,
  ROUND(COALESCE(c.corn_production_bu,      0),4) AS corn_production_bu,
  ROUND(COALESCE(m.mushroom_production_bu,  0),4) AS mushroom_production_bu
FROM corn AS c
FULL OUTER JOIN mushrooms AS m USING (state)
ORDER BY state;