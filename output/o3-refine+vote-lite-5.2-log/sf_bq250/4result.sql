WITH grid AS (   -- 1‑km population cells for Singapore, latest record before 2023‑01‑01
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid")               AS centroid_geog,
        ROW_NUMBER() OVER (PARTITION BY "geo_id"
                           ORDER BY "last_updated" DESC)                  AS rn
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),
latest_grid AS (                      -- keep most‑recent row per grid cell
    SELECT "geo_id", "population", centroid_geog
    FROM   grid
    WHERE  rn = 1
),
bounding AS (                         -- simple bounding region of all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(centroid_geog)) AS region_geog
    FROM   latest_grid
),
hospitals AS (                        -- OSM hospitals / doctors inside that region
    SELECT TO_GEOGRAPHY("geometry") AS hosp_geog
    FROM   GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, bounding
    WHERE  "layer_code" IN (2110, 2120)
      AND  "geometry" IS NOT NULL
      AND  ST_INTERSECTS(TO_GEOGRAPHY("geometry"), region_geog)
),
grid_hosp AS (                        -- distance from every grid cell to every hospital
    SELECT
        g."geo_id",
        g."population",
        ST_DISTANCE(g.centroid_geog, h.hosp_geog) AS dist
    FROM   latest_grid g
    JOIN   hospitals  h
),
min_dist_per_grid AS (                -- nearest hospital for each grid cell
    SELECT
        "geo_id",
        MAX("population") AS population,   -- same value within each geo_id
        MIN(dist)         AS min_dist
    FROM   grid_hosp
    GROUP  BY "geo_id"
)
SELECT population                     -- population of the cell farthest from any hospital
FROM   min_dist_per_grid
ORDER  BY min_dist DESC NULLS LAST, "geo_id"
LIMIT  1;