/*  Total population of the 1‑km Singapore grid‑cell that is farthest from
    any hospital (layer_code 2110 | 2120) using the latest grid vintage
    prior to 2023‑01‑01.  ST_ENVELOPE is used to build a bounding polygon
    for the grid‑cell centroids.                                             */
WITH recent_date AS (     -- latest grid snapshot before 2023‑01‑01
    SELECT MAX("last_updated") AS "dt"
    FROM   "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM"
    WHERE  "alpha_3_code" = 'SGP'
      AND  "last_updated" < '2023-01-01'
),
grid AS (                 -- Singapore grid cells for that date
    SELECT *
    FROM   "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM" g
           JOIN recent_date rd
             ON g."last_updated" = rd."dt"
    WHERE  g."alpha_3_code" = 'SGP'
),
hull AS (                 -- axis‑aligned bounding polygon of grid centroids
    SELECT ST_ENVELOPE(
             ST_COLLECT(
               ST_MAKEPOINT("longitude_centroid", "latitude_centroid")
             )
           ) AS "hull_geom"
    FROM   grid
),
hos AS (                  -- hospitals inside that bounding polygon
    SELECT ST_GEOGFROMWKB(pl."geometry") AS "hos_geom"
    FROM   "GEO_OPENSTREETMAP_WORLDPOP"."GEO_OPENSTREETMAP"."PLANET_LAYERS" pl,
           hull
    WHERE  pl."layer_code" IN (2110, 2120)
      AND  ST_INTERSECTS(
             ST_GEOGFROMWKB(pl."geometry"),
             hull."hull_geom"
           )
),
dist AS (                 -- distance of each grid cell to nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN(
          ST_DISTANCE(
              ST_MAKEPOINT(g."longitude_centroid", g."latitude_centroid"),
              h."hos_geom"
          )
        ) AS "nearest_hos_m"
    FROM   grid g
           CROSS JOIN hos h
    GROUP BY g."geo_id", g."population"
)
SELECT "population"
FROM   dist
ORDER  BY "nearest_hos_m" DESC
LIMIT  1;