-- 2022 state-level production totals for corn (bushels) and mushrooms
WITH corn AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year                = 2022
    AND group_desc          = 'FIELD CROPS'
    AND commodity_desc      = 'CORN'
    AND statisticcat_desc   = 'PRODUCTION'
    AND agg_level_desc      = 'STATE'
    AND unit_desc           = 'BU'         -- bushels only
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),
mushrooms AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushroom_total
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year                = 2022
    AND group_desc          = 'HORTICULTURE'
    AND commodity_desc      = 'MUSHROOMS'
    AND statisticcat_desc   = 'PRODUCTION'
    AND agg_level_desc      = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
)
SELECT
  COALESCE(c.state_alpha, m.state_alpha) AS state_alpha,
  COALESCE(c.state_name,  m.state_name)  AS state_name,
  COALESCE(c.corn_bu,     0)             AS corn_bu,
  COALESCE(m.mushroom_total, 0)          AS mushroom_total
FROM corn AS c
FULL OUTER JOIN mushrooms AS m
USING (state_alpha, state_name)
ORDER BY corn_bu DESC, state_name;