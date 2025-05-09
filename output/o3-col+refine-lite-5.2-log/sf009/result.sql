WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COUNT(*)                                         AS "AMS_BUILDING_COUNT",
        SUM(TRY_CAST("SURFACE_AREA_SQ_M" AS DOUBLE))    AS "AMS_TOTAL_SURFACE_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Amsterdam"%'
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COUNT(*)                                         AS "RTM_BUILDING_COUNT",
        SUM(TRY_CAST("SURFACE_AREA_SQ_M" AS DOUBLE))     AS "RTM_TOTAL_SURFACE_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Rotterdam"%'
    GROUP BY "CLASS", "SUBCLASS"
)
SELECT
    COALESCE(a."CLASS", r."CLASS")                       AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS")                 AS "SUBCLASS",
    NVL(a."AMS_BUILDING_COUNT", 0)                       AS "AMSTERDAM_BUILDING_COUNT",
    NVL(a."AMS_TOTAL_SURFACE_SQ_M", 0)                   AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    NVL(r."RTM_BUILDING_COUNT", 0)                       AS "ROTTERDAM_BUILDING_COUNT",
    NVL(r."RTM_TOTAL_SURFACE_SQ_M", 0)                   AS "ROTTERDAM_TOTAL_SURFACE_SQ_M"
FROM amsterdam a
FULL JOIN rotterdam r
       ON a."CLASS" = r."CLASS"
      AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY "CLASS", "SUBCLASS";