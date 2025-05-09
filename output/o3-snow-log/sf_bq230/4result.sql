SELECT
    "state_name"                                               AS "STATE",
    SUM(
        CASE
            WHEN "commodity_desc" = 'CORN'
                 AND "group_desc"  = 'FIELD CROPS'
                 AND "unit_desc"   = 'BU'
            THEN "value"
        END
    )                                                          AS "CORN_PRODUCTION_BU",
    SUM(
        CASE
            WHEN "commodity_desc"        LIKE 'MUSHROOM%'
                 AND "group_desc"        = 'HORTICULTURE'
            THEN "value"
        END
    )                                                          AS "MUSHROOM_PRODUCTION"
FROM  USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
WHERE "year"               = 2022
  AND "statisticcat_desc"  = 'PRODUCTION'
  AND "agg_level_desc"     = 'STATE'
  AND "value"              IS NOT NULL
  AND (
        /* keep only the two commodities of interest */
        ("commodity_desc" = 'CORN'      AND "group_desc" = 'FIELD CROPS'  AND "unit_desc" = 'BU')
     OR ("commodity_desc" LIKE 'MUSHROOM%' AND "group_desc" = 'HORTICULTURE')
      )
GROUP BY "state_name"
ORDER BY "state_name";