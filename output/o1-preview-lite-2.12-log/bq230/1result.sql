SELECT
  COALESCE(corn.state_name, mushrooms.state_name) AS state_name,
  corn.corn_production_bu,
  mushrooms.mushroom_production,
  mushrooms.mushroom_unit_desc
FROM (
  SELECT
    state_name,
    SUM(value) AS corn_production_bu
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE commodity_desc = 'CORN'
    AND group_desc = 'FIELD CROPS'
    AND year = 2022
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc = 'STATE'
    AND unit_desc = 'BU'
    AND value IS NOT NULL
  GROUP BY state_name
) AS corn
FULL OUTER JOIN (
  SELECT
    state_name,
    SUM(value) AS mushroom_production,
    ANY_VALUE(unit_desc) AS mushroom_unit_desc
  FROM `bigquery-public-data.usda_nass_agriculture.crops`
  WHERE commodity_desc = 'MUSHROOMS'
    AND group_desc = 'HORTICULTURE'
    AND year = 2022
    AND statisticcat_desc = 'PRODUCTION'
    AND agg_level_desc = 'STATE'
    AND value IS NOT NULL
  GROUP BY state_name
) AS mushrooms
ON corn.state_name = mushrooms.state_name