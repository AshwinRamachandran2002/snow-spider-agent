WITH filtered AS (
    SELECT
        "state_name",
        "commodity_desc",
        "value"
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year" = 2022
      AND "agg_level_desc" = 'STATE'
      AND "statisticcat_desc" = 'PRODUCTION'
      AND "unit_desc" = 'BU'                 -- bushels
      AND "value" IS NOT NULL
      AND (
            ("commodity_desc" = 'CORN'      AND "group_desc" = 'FIELD CROPS')
         OR ("commodity_desc" = 'MUSHROOMS' AND "group_desc" = 'HORTICULTURE')
          )
)

SELECT
    "state_name",
    SUM(CASE WHEN "commodity_desc" = 'CORN'      THEN "value" END) AS "corn_bu_2022",
    SUM(CASE WHEN "commodity_desc" = 'MUSHROOMS' THEN "value" END) AS "mushrooms_bu_2022"
FROM filtered
GROUP BY
    "state_name"
ORDER BY
    "state_name";