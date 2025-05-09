SELECT
  "state_name" AS "State_Name",
  "commodity_desc" AS "Commodity",
  ROUND(SUM(CAST("value" AS FLOAT)), 4) AS "Production",
  "unit_desc" AS "Unit"
FROM
  USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
WHERE
  "year" = '2022'
  AND "commodity_desc" IN ('CORN', 'MUSHROOMS')
  AND (
    ("commodity_desc" = 'CORN' AND "group_desc" = 'FIELD CROPS' AND "unit_desc" = 'BU')
    OR
    ("commodity_desc" = 'MUSHROOMS' AND "group_desc" = 'HORTICULTURE' AND "unit_desc" = 'LB')
  )
  AND "statisticcat_desc" = 'PRODUCTION'
  AND "agg_level_desc" = 'STATE'
  AND "value_suppression_code" IS NULL
  AND "value" IS NOT NULL
GROUP BY
  "state_name",
  "commodity_desc",
  "unit_desc"
ORDER BY
  "Commodity",
  "State_Name";