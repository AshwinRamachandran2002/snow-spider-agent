WITH corn AS (
    SELECT
        "state_name",
        SUM("value") AS "corn_bu"
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year"               = 2022
      AND "agg_level_desc"     = 'STATE'
      AND "statisticcat_desc"  = 'PRODUCTION'
      AND "group_desc"         = 'FIELD CROPS'
      AND "commodity_desc"     = 'CORN'
      AND "unit_desc"          = 'BU'          -- ensure corn is measured in bushels
      AND "value" IS NOT NULL
    GROUP BY "state_name"
), 
mushrooms AS (
    SELECT
        "state_name",
        SUM("value") AS "mushroom_prod"
    FROM USDA_NASS_AGRICULTURE.USDA_NASS_AGRICULTURE.CROPS
    WHERE "year"               = 2022
      AND "agg_level_desc"     = 'STATE'
      AND "statisticcat_desc"  = 'PRODUCTION'
      AND "group_desc"         = 'HORTICULTURE'
      AND "commodity_desc" LIKE 'MUSHROOM%'   -- includes MUSHROOMS, MUSHROOMS, AGARICUS, etc.
      AND "value" IS NOT NULL
    GROUP BY "state_name"
)
SELECT
    COALESCE(c."state_name", m."state_name") AS "state_name",
    c."corn_bu",
    m."mushroom_prod"
FROM corn c
FULL OUTER JOIN mushrooms m
  ON c."state_name" = m."state_name"
ORDER BY "state_name";