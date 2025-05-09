WITH corn AS (
  -- 2022 STATE-level corn production in bushels
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year               = 2022
    AND group_desc         = 'FIELD CROPS'
    AND commodity_desc     = 'CORN'
    AND statisticcat_desc  = 'PRODUCTION'
    AND unit_desc          = 'BU'      -- ensure corn is in bushels
    AND agg_level_desc     = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),
mushrooms AS (
  -- 2022 STATE-level mushroom production (reported unit is pounds)
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushrooms_total
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year               = 2022
    AND group_desc         = 'HORTICULTURE'
    AND commodity_desc     = 'MUSHROOMS'
    AND statisticcat_desc  = 'PRODUCTION'
    AND agg_level_desc     = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
)
SELECT
  COALESCE(c.state_alpha, m.state_alpha) AS state_alpha,
  COALESCE(c.state_name , m.state_name ) AS state_name,
  c.corn_bu,
  m.mushrooms_total
FROM corn c
FULL JOIN mushrooms m
ON c.state_alpha = m.state_alpha
ORDER BY state_alpha;