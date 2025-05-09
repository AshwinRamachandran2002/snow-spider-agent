/* 2022 State‑level production totals for Corn (bushels) and Mushrooms */
WITH
-- Corn: 2022, Field Crops, measured in bushels
corn AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
        year = 2022
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc   = 'STATE'
    AND group_desc       = 'FIELD CROPS'
    AND commodity_desc   = 'CORN'
    AND unit_desc        = 'BU'          -- ensure bushels for corn
    AND domain_desc      = 'TOTAL'       -- use state‑level totals only
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),

-- Mushrooms: 2022, Horticulture group (unit may differ)
mushrooms AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushroom_production
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
        year = 2022
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc   = 'STATE'
    AND group_desc       = 'HORTICULTURE'
    AND commodity_desc   = 'MUSHROOMS'
    AND domain_desc      = 'TOTAL'       -- use state‑level totals only
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
)

-- Combine both results so each state has its corn & mushroom totals
SELECT
  COALESCE(c.state_alpha, m.state_alpha) AS state_abbr,
  COALESCE(c.state_name,  m.state_name)  AS state_name,
  c.corn_production_bu,
  m.mushroom_production
FROM corn      AS c
FULL OUTER JOIN mushrooms AS m
ON c.state_alpha = m.state_alpha
ORDER BY state_name;