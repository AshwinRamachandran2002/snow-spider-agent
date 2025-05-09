/*  Total population of the Singapore 1-km grid cell that is farthest
    from any hospital/clinic (layer_code 2110 or 2120) using the most
    recent grid before 2023-01-01 and an ST_ENVELOPE search region     */
WITH latest_date AS (   -- most recent population grid before 2023-01-01
    SELECT MAX("last_updated") AS last_date
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "country_name" = 'Singapore'
      AND "last_updated" < '2023-01-01'
),
sg_grid AS (            -- grid cells for that date
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid","latitude_centroid") AS geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "country_name" = 'Singapore'
      AND "last_updated" = (SELECT last_date FROM latest_date)
),
region AS (             -- rectangular envelope around all centroids
    SELECT ST_ENVELOPE(ST_COLLECT(geom)) AS geom
    FROM sg_grid
),
hospitals AS (          -- OSM hospitals & clinics inside the envelope
    SELECT TO_GEOGRAPHY(p."geometry") AS geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS p,
         region r
    WHERE p."layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(TO_GEOGRAPHY(p."geometry"), r.geom)
),
grid_dist AS (          -- distance of every grid cell to nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.geom, h.geom)) AS min_dist
    FROM sg_grid g
    JOIN hospitals h ON TRUE
    GROUP BY g."geo_id", g."population"
)
SELECT
    "population" AS "total_population"
FROM grid_dist
ORDER BY min_dist DESC NULLS LAST
LIMIT 1;