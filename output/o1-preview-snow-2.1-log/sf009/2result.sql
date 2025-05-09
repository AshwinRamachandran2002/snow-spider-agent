WITH amsterdam_boundary AS (
    SELECT ST_UNION_AGG(t."GEO_CORDINATES") AS "GEO_CORDINATES"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
         LATERAL FLATTEN(input => t."NAMES") f
    WHERE t."ADMIN_LEVEL" = '8' AND f.value::STRING ILIKE '%Amsterdam%'
),
rotterdam_boundary AS (
    SELECT ST_UNION_AGG(t."GEO_CORDINATES") AS "GEO_CORDINATES"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
         LATERAL FLATTEN(input => t."NAMES") f
    WHERE t."ADMIN_LEVEL" = '8' AND f.value::STRING ILIKE '%Rotterdam%'
),
amsterdam_buildings AS (
    SELECT 'Amsterdam' AS "City",
           b."CLASS",
           b."SUBCLASS",
           TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") AS "SURFACE_AREA"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b, amsterdam_boundary a
    WHERE ST_INTERSECTS(b."GEO_CORDINATES", a."GEO_CORDINATES")
      AND TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") IS NOT NULL
),
rotterdam_buildings AS (
    SELECT 'Rotterdam' AS "City",
           b."CLASS",
           b."SUBCLASS",
           TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") AS "SURFACE_AREA"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b, rotterdam_boundary r
    WHERE ST_INTERSECTS(b."GEO_CORDINATES", r."GEO_CORDINATES")
      AND TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") IS NOT NULL
)
SELECT "City", "CLASS", "SUBCLASS",
       ROUND(SUM("SURFACE_AREA"), 4) AS "Total_Surface_Area_Sq_M",
       COUNT(*) AS "Number_of_Buildings"
FROM (
    SELECT * FROM amsterdam_buildings
    UNION ALL
    SELECT * FROM rotterdam_buildings
) AS all_buildings
GROUP BY "City", "CLASS", "SUBCLASS"
ORDER BY "City", "CLASS", "SUBCLASS";