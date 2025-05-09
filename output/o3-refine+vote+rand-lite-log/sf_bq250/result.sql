WITH latest AS (                     -- most recent grid vintage before 2023‑01‑01
    SELECT MAX("last_updated") AS dt
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
), 
sg_grid AS (                         -- 1‑km grid cells for Singapore
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid") AS centroid
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM, latest
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = latest.dt
), 
bounding AS (                        -- rectangular bounding region of all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(centroid)) AS region
    FROM sg_grid
), 
hospitals AS (                       -- hospitals within this region
    SELECT 
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, bounding
    WHERE "layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(TO_GEOGRAPHY("geometry"), region)
), 
grid_dist AS (                       -- distance from each grid cell to nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.centroid, h.geom)) AS min_dist
    FROM sg_grid g
    JOIN hospitals h
      ON TRUE
    GROUP BY g."geo_id", g."population"
), 
farthest AS (                        -- grid cell farthest from any hospital
    SELECT *
    FROM grid_dist
    ORDER BY min_dist DESC NULLS LAST
    LIMIT 1
)
SELECT
    "population" AS total_population_farthest_grid_cell
FROM farthest;