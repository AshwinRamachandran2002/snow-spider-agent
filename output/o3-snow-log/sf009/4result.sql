WITH building_city AS (   -- isolate buildings that have Amsterdam or Rotterdam in their address JSON
    SELECT
        "CLASS",
        "SUBCLASS",
        CASE
            WHEN "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Amsterdam"%'  THEN 'Amsterdam'
            WHEN "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Rotterdam"%'  THEN 'Rotterdam'
        END                                            AS "CITY",
        TRY_TO_DECIMAL("SURFACE_AREA_SQ_M")            AS "SURFACE_AREA_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Amsterdam"%'
       OR "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Rotterdam"%'
),                                                     -- aggregate per city / class / subclass
city_agg AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        "CITY",
        COUNT(*)                                      AS "NUM_BUILDINGS",
        SUM("SURFACE_AREA_SQ_M")                      AS "TOTAL_SURFACE_AREA_SQ_M"
    FROM building_city
    GROUP BY "CLASS", "SUBCLASS", "CITY"
)
-- pivot Amsterdam & Rotterdam statistics side-by-side
SELECT
    "CLASS",
    "SUBCLASS",
    COALESCE(MAX(CASE WHEN "CITY" = 'Amsterdam'  THEN "NUM_BUILDINGS"           END), 0) AS "AMSTERDAM_NUM_BUILDINGS",
    COALESCE(MAX(CASE WHEN "CITY" = 'Amsterdam'  THEN "TOTAL_SURFACE_AREA_SQ_M" END), 0) AS "AMSTERDAM_TOTAL_SURFACE_AREA_SQ_M",
    COALESCE(MAX(CASE WHEN "CITY" = 'Rotterdam'  THEN "NUM_BUILDINGS"           END), 0) AS "ROTTERDAM_NUM_BUILDINGS",
    COALESCE(MAX(CASE WHEN "CITY" = 'Rotterdam'  THEN "TOTAL_SURFACE_AREA_SQ_M" END), 0) AS "ROTTERDAM_TOTAL_SURFACE_AREA_SQ_M"
FROM city_agg
GROUP BY "CLASS", "SUBCLASS"
ORDER BY "CLASS" ASC, "SUBCLASS" ASC;