WITH latest_date AS (
    SELECT MAX("last_updated") AS d
    FROM "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM"
    WHERE "country_name" = 'Singapore'
      AND "last_updated" < DATE '2023-01-01'
),
sg_cells AS (
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid") AS geom
    FROM "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM", latest_date
    WHERE "country_name" = 'Singapore'
      AND "last_updated" = latest_date.d
),
bbox AS (  -- use bounding rectangle around all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(geom)) AS geom
    FROM sg_cells
),
hospitals AS (
    SELECT
        ST_CENTROID(ST_GEOGFROMWKB("geometry")) AS geom
    FROM "GEO_OPENSTREETMAP_WORLDPOP"."GEO_OPENSTREETMAP"."PLANET_LAYERS", bbox
    WHERE "layer_code" IN (2110, 2120)          -- hospitals & doctors
      AND ST_INTERSECTS(ST_GEOGFROMWKB("geometry"), bbox.geom)
),
distances AS (
    SELECT
        c."geo_id",
        c."population",
        MIN(ST_DISTANCE(c.geom, h.geom)) AS dist_m
    FROM sg_cells c
    JOIN hospitals h ON TRUE
    GROUP BY c."geo_id", c."population"
)
SELECT
    CAST(ROUND("population", 4) AS NUMBER(38,4)) AS "total_population"
FROM distances
ORDER BY dist_m DESC NULLS LAST, "geo_id"
LIMIT 1;