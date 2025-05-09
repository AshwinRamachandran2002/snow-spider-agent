WITH snapshot_date AS (   -- most recent 1‑km grid before 2023‑01‑01
    SELECT MAX("last_updated") AS dt
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),
sgp_grid AS (             -- Singapore grid centroids & population
    SELECT
        g."geo_id",
        g."population",
        ST_POINT(g."longitude_centroid", g."latitude_centroid") AS centroid_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM g
    JOIN snapshot_date s
      ON g."last_updated" = s.dt
    WHERE g."alpha_3_code" = 'SGP'
),
hull AS (                  -- bounding region of all centroids
    SELECT ST_ENVELOPE(ST_COLLECT(centroid_geom)) AS hull_geom
    FROM sgp_grid
),
hospitals AS (             -- OSM hospitals/clinics within the region
    SELECT TO_GEOGRAPHY(l."geometry") AS hosp_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS l
    JOIN hull h
      ON ST_INTERSECTS(TO_GEOGRAPHY(l."geometry"), h.hull_geom)
    WHERE l."layer_code" IN (2110, 2120)
),
grid_dist AS (             -- nearest‑hospital distance per grid cell
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.centroid_geom, h.hosp_geom)) AS nearest_dist_m
    FROM sgp_grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
)
SELECT
    ROUND("population", 4) AS total_population
FROM grid_dist
ORDER BY nearest_dist_m DESC NULLS LAST, "geo_id"
LIMIT 1;