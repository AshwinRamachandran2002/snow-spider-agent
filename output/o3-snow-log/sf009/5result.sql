/*--------------------------------------------------------------------
  Building-classification comparison between Amsterdam and Rotterdam
  ------------------------------------------------------------------*/
WITH
/* --- 1.  Administrative boundaries for the two cities -------------*/
amsterdam_boundary AS (          -- municipality of Amsterdam
    SELECT "GEO_CORDINATES"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'                 -- municipality level
       AND ( LOWER("NAMES":"local"::STRING) = 'amsterdam'
          OR LOWER("NAMES":"nl"   ::STRING) = 'amsterdam'
          OR LOWER("NAMES":"en"   ::STRING) = 'amsterdam')
),

rotterdam_boundary AS (          -- municipality of Rotterdam
    SELECT "GEO_CORDINATES"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'
       AND ( LOWER("NAMES":"local"::STRING) = 'rotterdam'
          OR LOWER("NAMES":"nl"   ::STRING) = 'rotterdam'
          OR LOWER("NAMES":"en"   ::STRING) = 'rotterdam')
),

/* --- 2.  Aggregated building statistics for Amsterdam -------------*/
amsterdam_stats AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(TRY_TO_DECIMAL(b."SURFACE_AREA_SQ_M")) AS "AMS_SURFACE_AREA_SQ_M",
        COUNT(*)                                   AS "AMS_TOTAL_BUILDINGS"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b,
           amsterdam_boundary ab
    WHERE  ST_CONTAINS(ab."GEO_CORDINATES", b."GEO_CORDINATES")
    GROUP  BY b."CLASS", b."SUBCLASS"
),

/* --- 3.  Aggregated building statistics for Rotterdam -------------*/
rotterdam_stats AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(TRY_TO_DECIMAL(b."SURFACE_AREA_SQ_M")) AS "ROT_SURFACE_AREA_SQ_M",
        COUNT(*)                                   AS "ROT_TOTAL_BUILDINGS"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b,
           rotterdam_boundary rb
    WHERE  ST_CONTAINS(rb."GEO_CORDINATES", b."GEO_CORDINATES")
    GROUP  BY b."CLASS", b."SUBCLASS"
)

/* --- 4.  Side-by-side comparison ---------------------------------*/
SELECT
    COALESCE(a."CLASS"   , r."CLASS")    AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",

    /* Amsterdam figures */
    a."AMS_SURFACE_AREA_SQ_M",
    a."AMS_TOTAL_BUILDINGS",

    /* Rotterdam figures */
    r."ROT_SURFACE_AREA_SQ_M",
    r."ROT_TOTAL_BUILDINGS"

FROM        amsterdam_stats  a
FULL OUTER JOIN rotterdam_stats r
       ON   a."CLASS" = r."CLASS"
      AND   NVL(a."SUBCLASS", '') = NVL(r."SUBCLASS", '')

ORDER BY    "CLASS" ASC NULLS LAST,
            "SUBCLASS" ASC NULLS LAST;