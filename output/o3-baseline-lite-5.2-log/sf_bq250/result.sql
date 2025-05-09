WITH singapore_grids AS (   -- latest (before 2023‑01‑01) 1‑km population grid for Singapore
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid","latitude_centroid") AS centroid_geog
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (
            SELECT MAX("last_updated")
            FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
            WHERE "alpha_3_code" = 'SGP'
              AND "last_updated" < '2023-01-01'
      )
),
bounding AS (   -- minimal bounding rectangle around all centroids
    SELECT ST_ENVELOPE( ST_UNION_AGG(centroid_geog) ) AS hull
    FROM   singapore_grids
),
hospitals AS (  -- hospitals / clinics within that rectangle
    SELECT
        TO_GEOGRAPHY("geometry") AS geog
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS
    WHERE "layer_code" IN (2110, 2120)          -- 2110 = hospital, 2120 = clinic/doctors
      AND ST_INTERSECTS(
              TO_GEOGRAPHY("geometry"),
              (SELECT hull FROM bounding)
          )
),
grid_with_dist AS (  -- min distance from each grid centroid to nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN( ST_DISTANCE(g.centroid_geog , h.geog) ) AS nearest_hosp_dist
    FROM singapore_grids g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
)
SELECT "population"         -- population of the grid cell farthest from any hospital
FROM   grid_with_dist
ORDER  BY nearest_hosp_dist DESC NULLS LAST, "geo_id"
LIMIT  1;