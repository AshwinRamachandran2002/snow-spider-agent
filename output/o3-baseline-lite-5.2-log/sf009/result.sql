/*---------------------------------------------------------------------------
  Comprehensive side‑by‑side comparison of building classifications
  between Amsterdam and Rotterdam.

  Result columns:
      CLASS                       – building class
      SUBCLASS                    – building subclass
      AMSTERDAM_SURFACE_AREA_SQ_M – summed surface area of all buildings
      AMSTERDAM_BUILDING_COUNT    – number of buildings
      ROTTERDAM_SURFACE_AREA_SQ_M – summed surface area of all buildings
      ROTTERDAM_BUILDING_COUNT    – number of buildings
---------------------------------------------------------------------------*/
WITH BUILDINGS_WITH_CITY AS (          -- 1. keep only buildings whose
    SELECT DISTINCT                    --    addresses specify the city
           b."ID",
           b."CLASS",
           b."SUBCLASS",
           TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")                    AS SURFACE_M2,
           addr.value:"addr:city"::string                          AS CITY
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b,
           LATERAL FLATTEN( INPUT => PARSE_JSON(b."CONTAINS_ADDRESSES") ) addr
    WHERE  addr.value:"addr:city"::string IN ('Amsterdam','Rotterdam')
),
CITY_AGG AS (                         -- 2. aggregate per class / subclass / city
    SELECT
        "CLASS",
        "SUBCLASS",
        CITY,
        SUM(SURFACE_M2) AS TOTAL_SURFACE_M2,
        COUNT(*)        AS BUILDING_CNT
    FROM BUILDINGS_WITH_CITY
    GROUP BY "CLASS","SUBCLASS",CITY
)

SELECT
    "CLASS",
    "SUBCLASS",
    /* Amsterdam statistics */
    COALESCE( SUM( CASE WHEN CITY = 'Amsterdam' THEN TOTAL_SURFACE_M2 END ), 0 ) AS AMSTERDAM_SURFACE_AREA_SQ_M,
    COALESCE( SUM( CASE WHEN CITY = 'Amsterdam' THEN BUILDING_CNT   END ), 0 )   AS AMSTERDAM_BUILDING_COUNT,

    /* Rotterdam statistics */
    COALESCE( SUM( CASE WHEN CITY = 'Rotterdam' THEN TOTAL_SURFACE_M2 END ), 0 ) AS ROTTERDAM_SURFACE_AREA_SQ_M,
    COALESCE( SUM( CASE WHEN CITY = 'Rotterdam' THEN BUILDING_CNT   END ), 0 )   AS ROTTERDAM_BUILDING_COUNT
FROM CITY_AGG
GROUP BY "CLASS","SUBCLASS"
ORDER BY "CLASS" ASC, "SUBCLASS" ASC;