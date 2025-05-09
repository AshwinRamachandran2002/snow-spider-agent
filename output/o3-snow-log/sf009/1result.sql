WITH city_boundaries AS ( 
    /* Build one polygon per city (municipality)                                    */
    SELECT 'Amsterdam' AS "CITY",
           ST_UNION_AGG("GEO_CORDINATES") AS "GEOM"
    FROM   "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ADMINISTRATIVE"
    WHERE  LOWER(CAST("NAMES" AS STRING)) LIKE '%amsterdam%'
      AND  "BOUNDARY" = 'administrative'

    UNION ALL

    SELECT 'Rotterdam' AS "CITY",
           ST_UNION_AGG("GEO_CORDINATES") AS "GEOM"
    FROM   "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ADMINISTRATIVE"
    WHERE  LOWER(CAST("NAMES" AS STRING)) LIKE '%rotterdam%'
      AND  "BOUNDARY" = 'administrative'
),

buildings_in_cities AS ( 
    /* Assign every building to the city whose boundary it intersects               */
    SELECT  b."CLASS",
            b."SUBCLASS",
            cb."CITY",
            TRY_TO_DECIMAL(b."SURFACE_AREA_SQ_M") AS "SURFACE_AREA"
    FROM    "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_BUILDING" b
    JOIN    city_boundaries cb
         ON ST_INTERSECTS(
                ST_CENTROID(b."GEO_CORDINATES"),   -- building centre
                cb."GEOM"                          -- city polygon
            )
)

SELECT
    "CLASS",
    "SUBCLASS",
    /* Amsterdam metrics */
    SUM(CASE WHEN "CITY" = 'Amsterdam'  THEN "SURFACE_AREA" ELSE 0 END) AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    COUNT_IF("CITY" = 'Amsterdam')                                       AS "AMSTERDAM_TOTAL_BUILDINGS",
    /* Rotterdam metrics */
    SUM(CASE WHEN "CITY" = 'Rotterdam' THEN "SURFACE_AREA" ELSE 0 END)   AS "ROTTERDAM_TOTAL_SURFACE_SQ_M",
    COUNT_IF("CITY" = 'Rotterdam')                                       AS "ROTTERDAM_TOTAL_BUILDINGS"
FROM   buildings_in_cities
GROUP  BY "CLASS", "SUBCLASS"
ORDER BY "CLASS" ASC NULLS LAST,
         "SUBCLASS" ASC NULLS LAST;