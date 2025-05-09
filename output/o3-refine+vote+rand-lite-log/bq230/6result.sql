WITH corn_production AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS corn_bu_2022
  FROM
    `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
        year = 2022
    AND agg_level_desc = 'STATE'
    AND statisticcat_desc = 'PRODUCTION'
    AND group_desc = 'FIELD CROPS'
    AND commodity_desc = 'CORN'
    AND unit_desc = 'BU'          -- bushels
    AND value IS NOT NULL
  GROUP BY
    state_alpha,
    state_name
),
mushroom_production AS (
  SELECT
    state_alpha,
    state_name,
    SUM(value) AS mushroom_prod_2022
  FROM
    `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE
        year = 2022
    AND agg_level_desc = 'STATE'
    AND statisticcat_desc = 'PRODUCTION'
    AND group_desc = 'HORTICULTURE'
    AND commodity_desc = 'MUSHROOMS'
    AND value IS NOT NULL
  GROUP BY
    state_alpha,
    state_name
)
SELECT
  COALESCE(c.state_alpha, m.state_alpha) AS state_alpha,
  COALESCE(c.state_name,  m.state_name)  AS state_name,
  c.corn_bu_2022,
  m.mushroom_prod_2022
FROM
  corn_production     AS c
FULL OUTER JOIN
  mushroom_production AS m
ON  c.state_alpha = m.state_alpha
ORDER BY
  state_alpha;