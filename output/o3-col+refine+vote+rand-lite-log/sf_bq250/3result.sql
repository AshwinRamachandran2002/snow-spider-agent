WITH sg_grid AS (   -- latest (<=2022-12-31) 1-km WorldPop grid for Singapore
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid") AS pt_geo   -- GEOGRAPHY point
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (
            SELECT MAX("last_updated")
            FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
            WHERE "alpha_3_code" = 'SGP'
              AND "last_updated" <= '2022-12-31'
      )
),
hull AS (   -- rectangular envelope of all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(pt_geo)) AS geom_hull
    FROM sg_grid
),
hospitals AS (   -- hospitals / doctors within the envelope
    SELECT TO_GEOGRAPHY("geometry") AS hosp_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS
    WHERE "layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(
            TO_GEOGRAPHY("geometry"),
            (SELECT geom_hull FROM hull)
          )
),
grid_distance AS (   -- distance from each grid cell to its nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.pt_geo, h.hosp_geom)) AS min_dist
    FROM sg_grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
)
SELECT "population"
FROM   grid_distance
ORDER  BY min_dist DESC NULLS LAST   -- farthest grid cell first
LIMIT  1;