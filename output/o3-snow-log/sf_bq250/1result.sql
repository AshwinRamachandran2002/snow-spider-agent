WITH sg_grid AS (  -- latest 1-km WorldPop grid for Singapore before 2023-01-01
    SELECT
        "geo_id",
        "population",
        ST_MAKEPOINT("longitude_centroid","latitude_centroid") AS geom   -- GEOGRAPHY
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (
            SELECT MAX("last_updated")
            FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
            WHERE "alpha_3_code" = 'SGP'
              AND "last_updated" < '2023-01-01'
        )
),
bounding_region AS (   -- bounding polygon around all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(geom)) AS geom
    FROM sg_grid
),
hospitals AS (         -- hospital locations inside that bounding polygon
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, bounding_region br
    WHERE "layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(TO_GEOGRAPHY("geometry"), br.geom)
),
grid_dist AS (         -- distance from each grid cell to its nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.geom, h.geom)) AS min_distance
    FROM sg_grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
)
SELECT
    "population" AS total_population_of_farthest_grid_cell
FROM grid_dist
ORDER BY min_distance DESC NULLS LAST
LIMIT 1;