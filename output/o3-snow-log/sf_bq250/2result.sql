WITH sgp_grid AS (   -- newest 1-km population grid for Singapore before 2023-01-01
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid")       AS centroid     -- GEOGRAPHY
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (
            SELECT MAX("last_updated")
            FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
            WHERE "alpha_3_code" = 'SGP'
              AND "last_updated" < '2023-01-01'
      )
),
sgp_hull AS (   -- bounding region (envelope) around all centroids
    SELECT ST_ENVELOPE(ST_COLLECT(centroid)) AS hull
    FROM sgp_grid
),
hospitals AS (   -- hospitals that fall inside that region
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, sgp_hull
    WHERE "layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(TO_GEOGRAPHY("geometry"), hull)
),
distances AS (   -- distance from each grid cell to its nearest hospital (metres)
    SELECT
        g."geo_id",
        g."population",
        MIN( ST_DISTANCE(g.centroid, h.geom) ) AS min_dist
    FROM sgp_grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
)
SELECT "population"
FROM distances
ORDER BY min_dist DESC NULLS LAST   -- grid cell farthest from any hospital
LIMIT 1;