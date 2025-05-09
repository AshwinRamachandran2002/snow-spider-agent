/* 2022 state‑level production totals, expressed in bushels,
   for corn (FIELD CROPS) and mushrooms (HORTICULTURE).        */

WITH corn AS (
  SELECT
    state_alpha                       AS state,
    ROUND(SUM(value), 4)              AS corn_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year                = 2022
    AND sector_desc          = 'CROPS'
    AND group_desc           = 'FIELD CROPS'
    AND commodity_desc       = 'CORN'
    AND statisticcat_desc    = 'PRODUCTION'
    AND agg_level_desc       = 'STATE'
    AND unit_desc            = 'BU'     -- bushels
    AND value               IS NOT NULL
    AND state_alpha NOT IN ('OT')       -- omit “OTHER STATES”
  GROUP BY state_alpha
),
mushrooms AS (
  SELECT
    state_alpha                       AS state,
    ROUND(SUM(value), 4)              AS mushroom_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year                = 2022
    AND sector_desc          = 'CROPS'
    AND group_desc           = 'HORTICULTURE'
    AND commodity_desc       = 'MUSHROOMS'
    AND statisticcat_desc    = 'PRODUCTION'
    AND agg_level_desc       = 'STATE'
    AND unit_desc            = 'BU'     -- bushels
    AND value               IS NOT NULL
    AND state_alpha NOT IN ('OT')
  GROUP BY state_alpha
)

SELECT
  COALESCE(c.state , m.state) AS state,
  c.corn_production_bu,
  m.mushroom_production_bu
FROM corn AS c
FULL JOIN mushrooms AS m
USING (state)
ORDER BY state;