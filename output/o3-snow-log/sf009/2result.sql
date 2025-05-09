/* -----------------------------------------------------------------
   Building-classification comparison between Amsterdam & Rotterdam
   -----------------------------------------------------------------*/
WITH CITY_POLYGONS AS
(
    /* 1. Municipality (admin_level = 8) polygons for both cities */
    SELECT
        LOWER( NAMES:"local"::string ) AS "CITY",
        "GEO_CORDINATES"              AS "CITY_GEOM"          -- already GEOGRAPHY
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE"
    WHERE "ADMIN_LEVEL" = '8'
      AND LOWER( NAMES:"local"::string ) IN ( 'amsterdam', 'rotterdam' )
),
BUILDINGS_IN_CITIES AS
(
    /* 2. Buildings whose footprint is inside the respective city */
    SELECT
        b."CLASS",
        b."SUBCLASS",
        c."CITY",
        TRY_TO_DECIMAL( b."SURFACE_AREA_SQ_M" ) AS "SURFACE_AREA_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b
    JOIN CITY_POLYGONS c
      ON ST_INTERSECTS( b."GEO_CORDINATES", c."CITY_GEOM" )
),
AGG AS
(
    /* 3. Aggregate per class / subclass / city */
    SELECT
        "CLASS",
        "SUBCLASS",
        "CITY",
        COUNT(*)                     AS "BUILDING_COUNT",
        SUM( "SURFACE_AREA_SQ_M" )   AS "TOTAL_SURFACE_SQ_M"
    FROM BUILDINGS_IN_CITIES
    GROUP BY "CLASS", "SUBCLASS", "CITY"
)

/* 4. Present Amsterdam & Rotterdam side-by-side */
SELECT
    "CLASS",
    "SUBCLASS",
    COALESCE( MAX( CASE WHEN "CITY" = 'amsterdam' THEN "BUILDING_COUNT"     END ), 0 ) AS "AMSTERDAM_BUILDING_COUNT",
    COALESCE( MAX( CASE WHEN "CITY" = 'amsterdam' THEN "TOTAL_SURFACE_SQ_M" END ), 0 ) AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    COALESCE( MAX( CASE WHEN "CITY" = 'rotterdam' THEN "BUILDING_COUNT"     END ), 0 ) AS "ROTTERDAM_BUILDING_COUNT",
    COALESCE( MAX( CASE WHEN "CITY" = 'rotterdam' THEN "TOTAL_SURFACE_SQ_M" END ), 0 ) AS "ROTTERDAM_TOTAL_SURFACE_SQ_M"
FROM AGG
GROUP BY "CLASS", "SUBCLASS"
ORDER BY "CLASS" ASC, "SUBCLASS" ASC;