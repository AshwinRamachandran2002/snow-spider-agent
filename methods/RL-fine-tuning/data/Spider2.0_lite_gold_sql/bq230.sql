SELECT
  COALESCE(corn.state_name, mushrooms.state_name) AS state_name,
  corn.corn_production_bu,
  mushrooms.mushroom_production,
  mushrooms.unit_desc
FROM
  (
    SELECT state_name, SUM(value) AS corn_production_bu
    FROM `bigquery-public-data.usda_nass_agriculture.crops`
    WHERE
      commodity_desc = 'CORN'
      AND group_desc = 'FIELD CROPS'
      AND statisticcat_desc = 'PRODUCTION'
      AND unit_desc = 'BU'
      AND agg_level_desc = 'STATE'
      AND year = 2022
      AND value IS NOT NULL
      AND state_name != 'OTHER STATES'
    GROUP BY state_name
  ) AS corn
FULL OUTER JOIN
  (
    SELECT state_name, SUM(value) AS mushroom_production, unit_desc
    FROM `bigquery-public-data.usda_nass_agriculture.crops`
    WHERE
      commodity_desc = 'MUSHROOMS'
      AND group_desc = 'HORTICULTURE'
      AND statisticcat_desc = 'PRODUCTION'
      AND agg_level_desc = 'STATE'
      AND year = 2022
      AND value IS NOT NULL
      AND state_name != 'OTHER STATES'
    GROUP BY state_name, unit_desc
  ) AS mushrooms
ON corn.state_name = mushrooms.state_name
ORDER BY state_name;