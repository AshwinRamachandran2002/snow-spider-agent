SELECT 
  state_name,
  ROUND(SUM(CASE WHEN commodity_desc = 'CORN' THEN value END), 4) AS corn_production_bu,
  ROUND(SUM(CASE WHEN commodity_desc = 'MUSHROOMS' THEN value END), 4) AS mushroom_production,
  MAX(CASE WHEN commodity_desc = 'MUSHROOMS' THEN unit_desc END) AS mushroom_unit_desc
FROM
  `bigquery-public-data.usda_nass_agriculture.crops`
WHERE
  statisticcat_desc = 'PRODUCTION' AND
  agg_level_desc = 'STATE' AND
  year = 2022 AND
  value IS NOT NULL AND
  (
    (commodity_desc = 'CORN' AND group_desc = 'FIELD CROPS' AND unit_desc = 'BU') OR
    (commodity_desc = 'MUSHROOMS' AND group_desc = 'HORTICULTURE')
  ) AND
  state_name NOT IN ('OTHER STATES', 'US TOTAL')
GROUP BY state_name;