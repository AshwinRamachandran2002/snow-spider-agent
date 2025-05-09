-- Total 2022 corn (FIELD CROPS) and mushroom (HORTICULTURE) production,
-- both measured in BUSHELS, by state
WITH corn AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_bu_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND commodity_desc = 'CORN'
    AND group_desc     = 'FIELD CROPS'
    AND statisticcat_desc = 'PRODUCTION'
    AND unit_desc      = 'BU'          -- bushels
    AND agg_level_desc = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),
mushroom AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushroom_bu_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE year = 2022
    AND commodity_desc LIKE '%MUSHROOM%'        -- covers "MUSHROOMS", "MUSHROOM, AGARICUS", etc.
    AND group_desc     = 'HORTICULTURE'
    AND statisticcat_desc = 'PRODUCTION'
    AND unit_desc      = 'BU'                   -- bushels
    AND agg_level_desc = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
)
SELECT
  COALESCE(c.state_alpha, m.state_alpha) AS state_alpha,
  COALESCE(c.state_name , m.state_name)  AS state_name,
  c.corn_bu_2022,
  m.mushroom_bu_2022
FROM corn AS c
FULL JOIN mushroom AS m
USING(state_alpha, state_name)
ORDER BY state_alpha;