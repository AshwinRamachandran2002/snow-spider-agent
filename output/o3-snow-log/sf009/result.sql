WITH city_boundaries AS (

    /* --- Administrative polygons for Amsterdam --- */
    SELECT
        'Amsterdam'                                         AS city ,
        "GEO_CORDINATES"                                    AS geom
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE "ADMIN_LEVEL" = '8'
      AND (
              LOWER("NAMES":local::string) = 'amsterdam'
           OR LOWER("NAMES":en::string)    = 'amsterdam'
           OR LOWER("NAMES":nl::string)    = 'amsterdam'
          )

    UNION ALL

    /* --- Administrative polygons for Rotterdam --- */
    SELECT
        'Rotterdam'                                         AS city ,
        "GEO_CORDINATES"                                    AS geom
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE "ADMIN_LEVEL" = '8'
      AND (
              LOWER("NAMES":local::string) = 'rotterdam'
           OR LOWER("NAMES":en::string)    = 'rotterdam'
           OR LOWER("NAMES":nl::string)    = 'rotterdam'
          )

),

/* --- Buildings that fall within either city boundary --- */
buildings_in_cities AS (
    SELECT
        b."CLASS" ,
        b."SUBCLASS" ,
        TRY_TO_DECIMAL(b."SURFACE_AREA_SQ_M")         AS surface_area ,
        cb.city
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b
    JOIN city_boundaries cb
      ON ST_INTERSECTS(b."GEO_CORDINATES", cb.geom)
)

SELECT
    "CLASS" ,
    "SUBCLASS" ,

    /* --- Amsterdam statistics --- */
    COALESCE(SUM(CASE WHEN city = 'Amsterdam' THEN surface_area END), 0)     AS "AMSTERDAM_TOTAL_SURFACE_AREA_SQ_M" ,
    COALESCE(SUM(CASE WHEN city = 'Amsterdam' THEN 1 END), 0)               AS "AMSTERDAM_BUILDING_COUNT" ,

    /* --- Rotterdam statistics --- */
    COALESCE(SUM(CASE WHEN city = 'Rotterdam' THEN surface_area END), 0)     AS "ROTTERDAM_TOTAL_SURFACE_AREA_SQ_M" ,
    COALESCE(SUM(CASE WHEN city = 'Rotterdam' THEN 1 END), 0)               AS "ROTTERDAM_BUILDING_COUNT"

FROM buildings_in_cities
GROUP BY
    "CLASS" ,
    "SUBCLASS"
ORDER BY
    "CLASS" ASC ,
    "SUBCLASS" ASC ;