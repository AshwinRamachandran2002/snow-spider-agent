WITH corn AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_bu_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
        year               = 2022
    AND group_desc         = 'FIELD CROPS'
    AND commodity_desc     = 'CORN'
    AND statisticcat_desc  = 'PRODUCTION'
    AND agg_level_desc     = 'STATE'
    AND unit_desc          = 'BU'      -- ensure corn is measured in bushels
    AND value IS NOT NULL
  GROUP BY state_alpha, state_name
),
mushrooms AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushrooms_prod_2022
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
        year               = 2022
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
  c.corn_bu_2022,
  m.mushrooms_prod_2022
FROM corn c
FULL JOIN mushrooms m USING (state_alpha, state_name)
ORDER BY state_alpha;