/* ------------------------------------------------------------------
   Side-by-side comparison of Amsterdam vs. Rotterdam building stock
   – total surface area (m²) and building count per CLASS / SUBCLASS
   -----------------------------------------------------------------*/
WITH
/* 1.  Municipality polygons (admin_level = 8) -----------------------*/
ams_poly AS (          -- Amsterdam
    SELECT a."GEO_CORDINATES"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE" a,
           LATERAL FLATTEN(input => a."NAMES") n
    WHERE  a."ADMIN_LEVEL" = '8'
      AND  n.VALUE::STRING = 'Amsterdam'
    LIMIT 1
),
rtm_poly AS (          -- Rotterdam
    SELECT a."GEO_CORDINATES"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE" a,
           LATERAL FLATTEN(input => a."NAMES") n
    WHERE  a."ADMIN_LEVEL" = '8'
      AND  n.VALUE::STRING = 'Rotterdam'
    LIMIT 1
),
/* 2.  Aggregate Amsterdam building statistics ----------------------*/
ams AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(b."SURFACE_AREA_SQ_M"::FLOAT)         AS "AMS_TOTAL_AREA_SQ_M",
        COUNT(*)                                   AS "AMS_TOTAL_BUILDINGS"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b,
           ams_poly ap
    WHERE  ST_CONTAINS(ap."GEO_CORDINATES",
                       ST_CENTROID(b."GEO_CORDINATES"))
    GROUP  BY b."CLASS", b."SUBCLASS"
),
/* 3.  Aggregate Rotterdam building statistics ----------------------*/
rtm AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(b."SURFACE_AREA_SQ_M"::FLOAT)         AS "RTM_TOTAL_AREA_SQ_M",
        COUNT(*)                                   AS "RTM_TOTAL_BUILDINGS"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b,
           rtm_poly rp
    WHERE  ST_CONTAINS(rp."GEO_CORDINATES",
                       ST_CENTROID(b."GEO_CORDINATES"))
    GROUP  BY b."CLASS", b."SUBCLASS"
)
/* 4.  Side-by-side comparison --------------------------------------*/
SELECT
    COALESCE(ams."CLASS",   rtm."CLASS")    AS "CLASS",
    COALESCE(ams."SUBCLASS",rtm."SUBCLASS") AS "SUBCLASS",
    ams."AMS_TOTAL_AREA_SQ_M",
    ams."AMS_TOTAL_BUILDINGS",
    rtm."RTM_TOTAL_AREA_SQ_M",
    rtm."RTM_TOTAL_BUILDINGS"
FROM      ams
FULL JOIN  rtm
      ON  ams."CLASS"    = rtm."CLASS"
     AND  ams."SUBCLASS" = rtm."SUBCLASS"
ORDER BY  "CLASS", "SUBCLASS";