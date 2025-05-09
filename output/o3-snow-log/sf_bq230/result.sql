WITH corn AS (
    SELECT
        "state_name",
        SUM("value") AS corn_bu_2022
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year" = 2022
      AND "agg_level_desc"   = 'STATE'
      AND "statisticcat_desc" = 'PRODUCTION'
      AND "group_desc"        = 'FIELD CROPS'
      AND "commodity_desc"    = 'CORN'
      AND "unit_desc"         = 'BU'          -- bushels
      AND "value" IS NOT NULL
    GROUP BY "state_name"
),
mushroom AS (
    SELECT
        "state_name",
        SUM("value") AS mushroom_bu_2022
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year" = 2022
      AND "agg_level_desc"   = 'STATE'
      AND "statisticcat_desc" = 'PRODUCTION'
      AND "group_desc"        = 'HORTICULTURE'
      AND UPPER("commodity_desc") LIKE 'MUSHROOM%'   -- include all mushroom items
      AND "value" IS NOT NULL
    GROUP BY "state_name"
)
SELECT
    COALESCE(c."state_name", m."state_name") AS "state_name",
    c.corn_bu_2022,
    m.mushroom_bu_2022
FROM corn      c
FULL OUTER JOIN mushroom m
       ON c."state_name" = m."state_name"
ORDER BY "state_name";