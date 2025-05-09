/* 2022 state‑level production (in bushels) of corn and mushrooms                */
SELECT
  state_alpha                          AS state,
  state_name,
  SUM(CASE WHEN commodity_desc = 'CORN'       THEN value END) AS corn_bushels_2022,
  SUM(CASE WHEN commodity_desc = 'MUSHROOMS'  THEN value END) AS mushroom_bushels_2022
FROM `bigquery-public-data.usda_nass_agriculture.crops`
WHERE
      year               = 2022
  AND agg_level_desc      = 'STATE'
  AND statisticcat_desc   = 'PRODUCTION'
  AND value              IS NOT NULL
  AND (
        (commodity_desc = 'CORN'      AND group_desc = 'FIELD CROPS'   AND unit_desc = 'BU')
     OR (commodity_desc = 'MUSHROOMS' AND group_desc = 'HORTICULTURE'  AND unit_desc = 'BU')
      )
GROUP BY state_alpha, state_name
ORDER BY state_alpha;