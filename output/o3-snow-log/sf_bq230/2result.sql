WITH prod AS (
    SELECT
        "state_alpha",
        "state_name",
        -- identify which commodity the row belongs to
        CASE 
            WHEN "commodity_desc" = 'CORN' THEN 'corn'
            WHEN "commodity_desc" = 'MUSHROOMS' THEN 'mushrooms'
        END                               AS commodity,
        CAST("value" AS FLOAT)             AS prod_value
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE
          "year"              = 2022
      AND "agg_level_desc"    = 'STATE'
      AND "statisticcat_desc" = 'PRODUCTION'
      AND "value"             IS NOT NULL
      AND (
              ( "commodity_desc" = 'CORN'
                AND "group_desc" = 'FIELD CROPS'
                AND "unit_desc"  = 'BU' )
           OR ( "commodity_desc" = 'MUSHROOMS'
                AND "group_desc" = 'HORTICULTURE' )
          )
)
SELECT
    "state_alpha",
    "state_name",
    SUM(CASE WHEN commodity = 'corn'      THEN prod_value END) AS corn_production_bu_2022,
    SUM(CASE WHEN commodity = 'mushrooms' THEN prod_value END) AS mushroom_production_2022
FROM prod
GROUP BY
    "state_alpha",
    "state_name"
ORDER BY
    "state_alpha";