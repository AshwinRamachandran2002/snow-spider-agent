WITH corn_production AS (
  SELECT
    "state_name",
    SUM(TRY_TO_DOUBLE("value")) AS "corn_production_bu"
  FROM
    "USDA_NASS_AGRICULTURE"."USDA_NASS_AGRICULTURE"."CROPS"
  WHERE
    "commodity_desc" = 'CORN' AND
    "group_desc" = 'FIELD CROPS' AND
    "statisticcat_desc" = 'PRODUCTION' AND
    "agg_level_desc" = 'STATE' AND
    "year" = '2022' AND
    "unit_desc" = 'BU' AND
    "value" IS NOT NULL
  GROUP BY
    "state_name"
),
mushroom_production AS (
  SELECT
    "state_name",
    SUM(TRY_TO_DOUBLE("value")) AS "mushroom_production_lb"
  FROM
    "USDA_NASS_AGRICULTURE"."USDA_NASS_AGRICULTURE"."CROPS"
  WHERE
    "commodity_desc" = 'MUSHROOMS' AND
    "group_desc" = 'HORTICULTURE' AND
    "statisticcat_desc" = 'PRODUCTION' AND
    "agg_level_desc" = 'STATE' AND
    "year" = '2022' AND
    "value" IS NOT NULL
  GROUP BY
    "state_name"
)
SELECT
  COALESCE(corn_production."state_name", mushroom_production."state_name") AS "state_name",
  corn_production."corn_production_bu",
  mushroom_production."mushroom_production_lb"
FROM
  corn_production
  FULL OUTER JOIN mushroom_production
    ON corn_production."state_name" = mushroom_production."state_name"
ORDER BY
  "state_name";