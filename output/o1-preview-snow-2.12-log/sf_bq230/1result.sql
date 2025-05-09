WITH corn_data AS (
  SELECT "state_name", SUM("value"::FLOAT) AS corn_production_bu
  FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
  WHERE
    "commodity_desc" = 'CORN' AND
    "group_desc" = 'FIELD CROPS' AND
    "unit_desc" = 'BU' AND
    "year" = '2022' AND
    "value" IS NOT NULL AND
    "statisticcat_desc" = 'PRODUCTION' AND
    "agg_level_desc" = 'STATE'
  GROUP BY "state_name"
),
mushroom_data AS (
  SELECT "state_name", SUM("value"::FLOAT) AS mushroom_production_unit
  FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
  WHERE
    "commodity_desc" = 'MUSHROOMS' AND
    "group_desc" = 'HORTICULTURE' AND
    "year" = '2022' AND
    "value" IS NOT NULL AND
    "statisticcat_desc" = 'PRODUCTION' AND
    "agg_level_desc" = 'STATE'
  GROUP BY "state_name"
)
SELECT
  COALESCE(corn_data."state_name", mushroom_data."state_name") AS "state_name",
  corn_data.corn_production_bu,
  mushroom_data.mushroom_production_unit
FROM corn_data
FULL OUTER JOIN mushroom_data
  ON corn_data."state_name" = mushroom_data."state_name"
ORDER BY "state_name";