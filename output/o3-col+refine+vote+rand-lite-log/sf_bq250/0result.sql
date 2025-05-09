/* Total population of the Singapore 1-km grid cell that is farthest from any
   hospital (layer_code 2110 or 2120) using the most-recent population grid
   before 2023-01-01. */
WITH latest_date AS (   -- most recent population grid date before 2023-01-01
    SELECT MAX("last_updated") AS "dt"
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),
pop_cells AS (          -- grid cells for that date (centroid as geography point)
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid") AS "cell_pt"
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM pc,
         latest_date ld
    WHERE pc."alpha_3_code" = 'SGP'
      AND pc."last_updated" = ld."dt"
),
hull AS (               -- rectangular bounding region around all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG("cell_pt")) AS "region"
    FROM pop_cells
),
hospitals AS (          -- hospitals inside that region
    SELECT TO_GEOGRAPHY(pl."geometry") AS "hosp_geom"
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS pl, hull h
    WHERE pl."layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(TO_GEOGRAPHY(pl."geometry"), h."region")
),
distances AS (          -- distance from each cell to its nearest hospital
    SELECT
        pc."geo_id",
        pc."population",
        MIN(ST_DISTANCE(pc."cell_pt", h."hosp_geom")) AS "min_dist_m"
    FROM pop_cells pc
    CROSS JOIN hospitals h
    GROUP BY pc."geo_id", pc."population"
)
SELECT
    "population" AS "total_population_farthest_cell"
FROM distances
ORDER BY "min_dist_m" DESC NULLS LAST
LIMIT 1;