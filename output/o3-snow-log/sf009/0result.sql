/* --------------------------------------------------------------------- 
   Building-class comparison between Amsterdam and Rotterdam
   ------------------------------------------------------------------ */
WITH
/* ---- pick the municipality (admin_level = 8) boundary polygons ---- */
ams_boundary AS (
    SELECT "GEO_CORDINATES" AS geom
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'
      AND  UPPER(TO_VARCHAR("NAMES")) LIKE '%AMSTERDAM%'
    LIMIT  1        /* the city polygon */
),
rot_boundary AS (
    SELECT "GEO_CORDINATES" AS geom
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'
      AND  UPPER(TO_VARCHAR("NAMES")) LIKE '%ROTTERDAM%'
    LIMIT  1        /* the city polygon */
),

/* ---------------- aggregate Amsterdam buildings ------------------- */
ams AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M"))              AS amsterdam_surface_area_sq_m,
        COUNT(*)                                               AS amsterdam_building_count
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b
    JOIN   ams_boundary ab
           ON ST_WITHIN(ST_CENTROID(b."GEO_CORDINATES"), ab.geom)
    GROUP  BY b."CLASS", b."SUBCLASS"
),

/* ---------------- aggregate Rotterdam buildings ------------------- */
rot AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M"))              AS rotterdam_surface_area_sq_m,
        COUNT(*)                                               AS rotterdam_building_count
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b
    JOIN   rot_boundary rb
           ON ST_WITHIN(ST_CENTROID(b."GEO_CORDINATES"), rb.geom)
    GROUP  BY b."CLASS", b."SUBCLASS"
)

/* --------- side-by-side comparison, ordered for readability ------- */
SELECT
    COALESCE(a."CLASS", r."CLASS")           AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS")     AS "SUBCLASS",
    a.amsterdam_surface_area_sq_m,
    a.amsterdam_building_count,
    r.rotterdam_surface_area_sq_m,
    r.rotterdam_building_count
FROM   ams a
FULL   OUTER JOIN rot r
       ON NVL(a."CLASS",   '#') = NVL(r."CLASS",   '#')
      AND NVL(a."SUBCLASS",'#') = NVL(r."SUBCLASS",'#')
ORDER  BY "CLASS" ASC NULLS LAST,
          "SUBCLASS" ASC NULLS LAST;