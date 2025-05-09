SELECT
  state_name,
  commodity_desc,
  unit_desc,
  SUM(value) AS production
FROM
  `bigquery-public-data.usda_nass_agriculture.crops`
WHERE
  (
    (commodity_desc = 'CORN' AND group_desc = 'FIELD CROPS' AND unit_desc = 'BU')
    OR
    (commodity_desc = 'MUSHROOMS' AND group_desc = 'HORTICULTURE' AND unit_desc = 'LB')
  )
  AND sector_desc = 'CROPS'
  AND statisticcat_desc = 'PRODUCTION'
  AND agg_level_desc = 'STATE'
  AND year = 2022
  AND value IS NOT NULL
  AND state_name IS NOT NULL
  AND value_suppression_code IS NULL
GROUP BY
  state_name,
  commodity_desc,
  unit_desc
ORDER BY
  state_name,
  commodity_desc;