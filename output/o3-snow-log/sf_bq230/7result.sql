WITH corn AS (
    SELECT
        "state_alpha",
        "state_name",
        SUM("value") AS "corn_production_bu"
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year"               = 2022
      AND "agg_level_desc"     = 'STATE'
      AND "statisticcat_desc"  = 'PRODUCTION'
      AND "commodity_desc"     = 'CORN'
      AND "group_desc"         = 'FIELD CROPS'
      AND "unit_desc"          = 'BU'
      AND "value" IS NOT NULL
    GROUP BY "state_alpha", "state_name"
),
mushrooms AS (
    SELECT
        "state_alpha",
        "state_name",
        SUM("value") AS "mushroom_production"
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year"               = 2022
      AND "agg_level_desc"     = 'STATE'
      AND "statisticcat_desc"  = 'PRODUCTION'
      AND "commodity_desc"     = 'MUSHROOMS'
      AND "group_desc"         = 'HORTICULTURE'
      AND "value" IS NOT NULL
    GROUP BY "state_alpha", "state_name"
)
SELECT
    COALESCE(c."state_alpha", m."state_alpha") AS "state_alpha",
    COALESCE(c."state_name",  m."state_name")  AS "state_name",
    c."corn_production_bu",
    m."mushroom_production"
FROM corn c
FULL OUTER JOIN mushrooms m
  ON c."state_alpha" = m."state_alpha"
ORDER BY "state_name" NULLS LAST;