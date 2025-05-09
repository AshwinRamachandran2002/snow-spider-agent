/*--------------------------------------------------------------------
  Building-class comparison between Amsterdam and Rotterdam
--------------------------------------------------------------------*/
WITH
/*------------------------------------------------------------------*/
/* 1.  Filter buildings whose embedded address list mentions         */
/*     “Amsterdam” or “Rotterdam” as city.                           */
/*------------------------------------------------------------------*/
"AMSTERDAM_BUILDINGS" AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        TRY_TO_DECIMAL("SURFACE_AREA_SQ_M") AS "SURFACE_AREA_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Amsterdam"%'
),
"ROTTERDAM_BUILDINGS" AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        TRY_TO_DECIMAL("SURFACE_AREA_SQ_M") AS "SURFACE_AREA_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"
    WHERE "CONTAINS_ADDRESSES" ILIKE '%"addr:city":"Rotterdam"%'
),

/*------------------------------------------------------------------*/
/* 2.  Aggregate per class / subclass for each city.                */
/*------------------------------------------------------------------*/
"AGG_AMS" AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COUNT(*)                                         AS "AMSTERDAM_BUILDING_COUNT",
        ROUND( COALESCE(SUM("SURFACE_AREA_SQ_M"),0), 4 ) AS "AMSTERDAM_TOTAL_SURFACE_AREA_SQ_M"
    FROM "AMSTERDAM_BUILDINGS"
    GROUP BY "CLASS", "SUBCLASS"
),
"AGG_ROT" AS (
    SELECT
        "CLASS",
        "SUBCLASS",
        COUNT(*)                                         AS "ROTTERDAM_BUILDING_COUNT",
        ROUND( COALESCE(SUM("SURFACE_AREA_SQ_M"),0), 4 ) AS "ROTTERDAM_TOTAL_SURFACE_AREA_SQ_M"
    FROM "ROTTERDAM_BUILDINGS"
    GROUP BY "CLASS", "SUBCLASS"
)

/*------------------------------------------------------------------*/
/* 3.  Side-by-side comparison.                                     */
/*------------------------------------------------------------------*/
SELECT
    COALESCE(a."CLASS"   , r."CLASS")    AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",

    /* Amsterdam metrics */
    a."AMSTERDAM_BUILDING_COUNT",
    a."AMSTERDAM_TOTAL_SURFACE_AREA_SQ_M",

    /* Rotterdam metrics */
    r."ROTTERDAM_BUILDING_COUNT",
    r."ROTTERDAM_TOTAL_SURFACE_AREA_SQ_M"

FROM "AGG_AMS" a
FULL OUTER JOIN "AGG_ROT" r
      ON  a."CLASS"    = r."CLASS"
      AND NVL(a."SUBCLASS", '__NULL__') = NVL(r."SUBCLASS", '__NULL__')

ORDER BY
    "CLASS"    ASC NULLS LAST,
    "SUBCLASS" ASC NULLS LAST;