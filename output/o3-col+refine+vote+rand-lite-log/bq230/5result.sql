/* 2022 state-level production totals for corn (bushels) and mushrooms (pounds) */
WITH corn AS (
  SELECT
    state_name,
    SUM(value) AS corn_bushels_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year               = 2022
    AND agg_level_desc     = 'STATE'
    AND statisticcat_desc  = 'PRODUCTION'
    AND group_desc         = 'FIELD CROPS'
    AND commodity_desc     = 'CORN'
    AND unit_desc          = 'BU'        -- bushels
    AND value IS NOT NULL
  GROUP BY state_name
),
mush AS (
  SELECT
    state_name,
    SUM(value) AS mushroom_pounds_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year               = 2022
    AND agg_level_desc     = 'STATE'
    AND statisticcat_desc  = 'PRODUCTION'
    AND group_desc         = 'HORTICULTURE'
    AND commodity_desc     = 'MUSHROOMS'
    AND unit_desc          = 'LB'        -- pounds
    AND value IS NOT NULL
  GROUP BY state_name
)
SELECT
  COALESCE(corn.state_name, mush.state_name) AS state_name,
  corn.corn_bushels_2022,
  mush.mushroom_pounds_2022
FROM corn
FULL OUTER JOIN mush
  ON corn.state_name = mush.state_name
ORDER BY state_name;