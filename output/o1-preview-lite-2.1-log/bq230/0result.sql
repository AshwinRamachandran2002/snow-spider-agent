SELECT
  state_name,
  commodity_desc,
  SUM(value) AS production_bushels
FROM
  `bigquery-public-data.usda_nass_agriculture.crops`
WHERE
  year = 2022
  AND agg_level_desc = 'STATE'
  AND statisticcat_desc = 'PRODUCTION'
  AND unit_desc = 'BU'
  AND value IS NOT NULL
  AND commodity_desc = 'CORN'
  AND group_desc = 'FIELD CROPS'
GROUP BY
  state_name,
  commodity_desc
ORDER BY
  state_name;