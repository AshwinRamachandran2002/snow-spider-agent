SELECT
  "state_name" AS "State_Name",
  "commodity_desc" AS "Commodity",
  ROUND("value", 4) AS "Production_Bushels"
FROM
  "USDA_NASS_AGRICULTURE"."USDA_NASS_AGRICULTURE"."CROPS"
WHERE
  "year" = 2022
  AND "statisticcat_desc" = 'PRODUCTION'
  AND "agg_level_desc" = 'STATE'
  AND "unit_desc" = 'BU'
  AND "value" IS NOT NULL
  AND (
    ("commodity_desc" = 'CORN' AND "group_desc" = 'FIELD CROPS')
    OR ("commodity_desc" = 'MUSHROOMS' AND "group_desc" = 'HORTICULTURE')
  );