WITH amsterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COUNT(*)                                   AS "amsterdam_building_count",
        SUM(TRY_TO_DOUBLE("SURFACE_AREA_SQ_M"))    AS "amsterdam_total_surface_sq_m"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Amsterdam"%'
    GROUP BY "CLASS", "SUBCLASS"
),
rotterdam AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COUNT(*)                                   AS "rotterdam_building_count",
        SUM(TRY_TO_DOUBLE("SURFACE_AREA_SQ_M"))    AS "rotterdam_total_surface_sq_m"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Rotterdam"%'
    GROUP BY "CLASS", "SUBCLASS"
)
SELECT
    COALESCE(a."CLASS",  r."CLASS")     AS "CLASS",
    COALESCE(a."SUBCLASS",r."SUBCLASS") AS "SUBCLASS",
    a."amsterdam_building_count",
    a."amsterdam_total_surface_sq_m",
    r."rotterdam_building_count",
    r."rotterdam_total_surface_sq_m"
FROM amsterdam AS a
FULL OUTER JOIN rotterdam AS r
      ON a."CLASS"    = r."CLASS"
     AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY
    "CLASS",
    "SUBCLASS";