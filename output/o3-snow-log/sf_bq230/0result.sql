WITH corn AS (
    SELECT
        "state_name",
        SUM( TO_NUMBER( REPLACE("value", ',', '') ) ) AS corn_production_bu
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year"               = 2022
      AND "group_desc"         = 'FIELD CROPS'
      AND "commodity_desc"     = 'CORN'
      AND "statisticcat_desc"  = 'PRODUCTION'
      AND "agg_level_desc"     = 'STATE'
      AND "unit_desc"          = 'BU'
      AND "value" IS NOT NULL
    GROUP BY "state_name"
),
mushrooms AS (
    SELECT
        "state_name",
        SUM( TO_NUMBER( REPLACE("value", ',', '') ) ) AS mushroom_production
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year"               = 2022
      AND "group_desc"         = 'HORTICULTURE'
      AND "commodity_desc" ILIKE 'MUSHROOM%'          -- captures MUSHROOMS, MUSHROOMS, AGARICUS, etc.
      AND "statisticcat_desc"  = 'PRODUCTION'
      AND "agg_level_desc"     = 'STATE'
      AND "value" IS NOT NULL
    GROUP BY "state_name"
)
SELECT
    COALESCE(c."state_name", m."state_name")        AS "STATE_NAME",
    c.corn_production_bu                            AS "CORN_PRODUCTION_BU",
    m.mushroom_production                           AS "MUSHROOM_PRODUCTION"
FROM corn c
FULL OUTER JOIN mushrooms m
       ON c."state_name" = m."state_name"
ORDER BY "STATE_NAME";