WITH singapore_grid AS (        -- latest (<2023-01-01) 1-km population grid for Singapore
    SELECT
        "geo_id",
        "population",
        ST_MAKEPOINT("longitude_centroid", "latitude_centroid")            AS centroid_geom   -- GEOGRAPHY
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "geo_id"
                               ORDER BY "last_updated" DESC) = 1
),
bounding_region AS (            -- rectangular bounding region around all centroids
    SELECT ST_ENVELOPE( ST_UNION_AGG(centroid_geom) ) AS bound_geom
    FROM singapore_grid
),
hospitals AS (                   -- hospital / clinic geometries inside the bounding region
    SELECT TO_GEOGRAPHY("geometry") AS hosp_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, bounding_region
    WHERE "layer_code" IN (2110, 2120)
      AND "geometry" IS NOT NULL
      AND ST_INTERSECTS( TO_GEOGRAPHY("geometry"), bound_geom )
),
grid_hosp_distances AS (         -- distance from each grid-cell centroid to nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN( ST_DISTANCE( g.centroid_geom , h.hosp_geom ) ) AS nearest_hosp_dist
    FROM singapore_grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
)
-- population of the grid cell farthest from any hospital
SELECT "population"
FROM grid_hosp_distances
ORDER BY nearest_hosp_dist DESC NULLS LAST
LIMIT 1;