WITH corn AS (
  SELECT
    state_name,
    SUM(value) AS corn_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND agg_level_desc      = 'STATE'
    AND statisticcat_desc   = 'PRODUCTION'
    AND commodity_desc      = 'CORN'
    AND group_desc          = 'FIELD CROPS'
    AND unit_desc           = 'BU'          -- already in bushels
    AND domain_desc         = 'TOTAL'       -- avoid double–counting
    AND value IS NOT NULL
  GROUP BY state_name
),
mushrooms AS (
  /* mushrooms reported in pounds; convert to bushels (≈12 lb = 1 bu) */
  SELECT
    state_name,
    SUM(value) / 12.0 AS mushroom_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND agg_level_desc      = 'STATE'
    AND statisticcat_desc   = 'PRODUCTION'
    AND commodity_desc      = 'MUSHROOMS'
    AND group_desc          = 'HORTICULTURE'
    AND unit_desc           = 'LB'
    AND domain_desc         = 'TOTAL'
    AND value IS NOT NULL
  GROUP BY state_name
)
SELECT
  COALESCE(c.state_name, m.state_name)            AS state,
  ROUND(c.corn_production_bu,     4)              AS corn_production_bu,
  ROUND(m.mushroom_production_bu, 4)              AS mushroom_production_bu
FROM corn c
FULL OUTER JOIN mushrooms m
USING (state_name)
ORDER BY state;