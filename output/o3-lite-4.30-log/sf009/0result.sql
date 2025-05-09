WITH amsterdam_area AS (
    /* Amsterdam municipality polygon (admin level 8) */
    SELECT ST_UNION_AGG("GEO_CORDINATES") AS "POLY"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE",
           LATERAL FLATTEN(input => "NAMES") f
    WHERE  f.value::STRING ILIKE '%Amsterdam%'
      AND  "ADMIN_LEVEL" = '8'
),
rotterdam_area AS (
    /* Rotterdam municipality polygon (admin level 8) */
    SELECT ST_UNION_AGG("GEO_CORDINATES") AS "POLY"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE",
           LATERAL FLATTEN(input => "NAMES") f
    WHERE  f.value::STRING ILIKE '%Rotterdam%'
      AND  "ADMIN_LEVEL" = '8'
),
amsterdam_stats AS (
    SELECT
           b."CLASS",
           b."SUBCLASS",
           COUNT(*)                                   AS amsterdam_total_buildings,
           SUM(b."SURFACE_AREA_SQ_M"::FLOAT)          AS amsterdam_total_surface_sqm
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b
    JOIN   amsterdam_area a
          ON ST_CONTAINS(a."POLY", ST_CENTROID(b."GEO_CORDINATES"))
    GROUP  BY b."CLASS", b."SUBCLASS"
),
rotterdam_stats AS (
    SELECT
           b."CLASS",
           b."SUBCLASS",
           COUNT(*)                                   AS rotterdam_total_buildings,
           SUM(b."SURFACE_AREA_SQ_M"::FLOAT)          AS rotterdam_total_surface_sqm
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b
    JOIN   rotterdam_area r
          ON ST_CONTAINS(r."POLY", ST_CENTROID(b."GEO_CORDINATES"))
    GROUP  BY b."CLASS", b."SUBCLASS"
)
SELECT
       COALESCE(a."CLASS",  r."CLASS")       AS "building_class",
       COALESCE(a."SUBCLASS", r."SUBCLASS")  AS "building_subclass",
       ROUND(a.amsterdam_total_surface_sqm, 4)   AS "amsterdam_total_surface_sqm",
       a.amsterdam_total_buildings              AS "amsterdam_total_buildings",
       ROUND(r.rotterdam_total_surface_sqm, 4)   AS "rotterdam_total_surface_sqm",
       r.rotterdam_total_buildings              AS "rotterdam_total_buildings"
FROM   amsterdam_stats a
FULL OUTER JOIN rotterdam_stats r
       ON  a."CLASS" = r."CLASS"
       AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY
       "building_class",
       "building_subclass";