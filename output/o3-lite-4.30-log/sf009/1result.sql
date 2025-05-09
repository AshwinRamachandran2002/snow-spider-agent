WITH city_polygons AS (
    SELECT 'Amsterdam' AS city, a."GEO_CORDINATES" AS geom
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE a,
         LATERAL FLATTEN(input => a."NAMES") n
    WHERE n.value::string ILIKE '%Amsterdam%'
      AND a."ADMIN_LEVEL" = '8'
    UNION ALL
    SELECT 'Rotterdam' AS city, a."GEO_CORDINATES" AS geom
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE a,
         LATERAL FLATTEN(input => a."NAMES") n
    WHERE n.value::string ILIKE '%Rotterdam%'
      AND a."ADMIN_LEVEL" = '8'
),
buildings_in_cities AS (
    SELECT
        cp.city,
        b."CLASS"    AS building_class,
        b."SUBCLASS" AS building_subclass,
        TRY_CAST(b."SURFACE_AREA_SQ_M" AS FLOAT) AS surface_sqm
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b,
         city_polygons cp
    WHERE ST_WITHIN(b."GEO_CORDINATES", cp.geom)
)
SELECT
    building_class,
    building_subclass,
    ROUND(SUM(CASE WHEN city = 'Amsterdam' THEN surface_sqm END), 4)  AS amsterdam_total_surface_sqm,
    SUM(CASE WHEN city = 'Amsterdam' THEN 1 END)                      AS amsterdam_total_buildings,
    ROUND(SUM(CASE WHEN city = 'Rotterdam' THEN surface_sqm END), 4) AS rotterdam_total_surface_sqm,
    SUM(CASE WHEN city = 'Rotterdam' THEN 1 END)                      AS rotterdam_total_buildings
FROM buildings_in_cities
GROUP BY building_class, building_subclass
ORDER BY building_class, building_subclass;