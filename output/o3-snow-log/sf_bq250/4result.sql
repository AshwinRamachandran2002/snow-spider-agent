/*  Grid vintage < 2023, Singapore → envelope of centroids;
    hospitals (layer_code 2110 / 2120) inside that envelope;
    distance of every grid-cell centroid to nearest hospital;
    population of the cell farthest from any hospital          */

WITH latest_date AS (                    -- most recent grid prior to 2023
    SELECT MAX("last_updated") AS dt
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),
sg_grid AS (                             -- grid cells of that vintage
    SELECT
        "geo_id",
        "population",
        TO_GEOGRAPHY(ST_MAKEPOINT("longitude_centroid","latitude_centroid")) AS centroid
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM g
    JOIN latest_date l
      ON g."last_updated" = l.dt
    WHERE g."alpha_3_code" = 'SGP'
),
bounding AS (                            -- bounding envelope of all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(centroid)) AS region
    FROM sg_grid
),
hospitals AS (                           -- hospitals within that envelope
    SELECT
        ST_CENTROID(TO_GEOGRAPHY(p."geometry")) AS geom_center
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS p
    JOIN bounding b
      ON ST_INTERSECTS(TO_GEOGRAPHY(p."geometry"), b.region)
    WHERE p."layer_code" IN (2110, 2120)
),
grid_dist AS (                           -- nearest-hospital distance per grid cell
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.centroid, h.geom_center)) AS min_distance
    FROM sg_grid g
    JOIN hospitals h
      ON TRUE
    GROUP BY g."geo_id", g."population"
)
SELECT
    "population"
FROM grid_dist
ORDER BY min_distance DESC NULLS LAST    -- farthest cell first
LIMIT 1;