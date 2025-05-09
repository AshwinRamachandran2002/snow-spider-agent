WITH sgp_grid AS (   -- latest 1-km population grid for Singapore before 2023-01-01
    SELECT
        "geo_id",
        "population",
        TO_GEOGRAPHY(
            'POINT(' || "longitude_centroid" || ' ' || "latitude_centroid" || ')'
        )                                                    AS centroid_geog
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (
            SELECT MAX("last_updated")
            FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
            WHERE "alpha_3_code" = 'SGP'
              AND "last_updated" < DATE '2023-01-01'
          )
),
hull AS (  -- bounding envelope around all centroids (use ST_ENVELOPE instead of ST_CONVEXHULL)
    SELECT ST_ENVELOPE(ST_UNION_AGG(centroid_geog)) AS region_geog
    FROM sgp_grid
),
hospitals AS (  -- hospital geometries inside the bounding region
    SELECT TO_GEOGRAPHY("geometry") AS hosp_geog
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS
    WHERE "layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(
            (SELECT region_geog FROM hull),
            TO_GEOGRAPHY("geometry")
          )
),
grid_dist AS (  -- distance from each grid centroid to its nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN( ST_DISTANCE(g.centroid_geog, h.hosp_geog) ) AS min_dist
    FROM sgp_grid g
    JOIN hospitals h ON TRUE
    GROUP BY g."geo_id", g."population"
),
farthest AS (  -- grid cell farthest from any hospital
    SELECT *
    FROM grid_dist
    ORDER BY min_dist DESC NULLS LAST
    LIMIT 1
)
SELECT "population"
FROM farthest;