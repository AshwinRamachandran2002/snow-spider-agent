WITH latest_date AS (   -- most recent WorldPop vintage before 2023 for Singapore
    SELECT MAX("last_updated") AS "max_date"
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),

pop AS (                -- Singapore 1 km grid cells (centroids as geography points)
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid", "latitude_centroid")        AS "centroid_geog"
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM p
    JOIN latest_date d
      ON p."last_updated" = d."max_date"
    WHERE p."alpha_3_code" = 'SGP'
),

boundary AS (           -- bounding envelope around all centroids
    SELECT
        ST_ENVELOPE(ST_UNION_AGG("centroid_geog"))                 AS "bbox_geog"
    FROM pop
),

hospitals AS (          -- hospitals lying inside that bounding box
    SELECT
        TO_GEOGRAPHY("geometry")                                   AS "hospital_geog"
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, boundary
    WHERE "layer_code" IN (2110, 2120)           -- 2110 = hospital, 2120 = doctors
      AND ST_INTERSECTS(TO_GEOGRAPHY("geometry"), boundary."bbox_geog")
),

pop_hosp_dist AS (      -- distance from every grid cell to every hospital
    SELECT
        p."geo_id",
        p."population",
        ST_DISTANCE(p."centroid_geog", h."hospital_geog")          AS "dist_m"
    FROM pop p
    CROSS JOIN hospitals h
),

pop_with_min_dist AS (  -- nearest‑hospital distance per grid cell
    SELECT
        "geo_id",
        "population",
        MIN("dist_m")                                              AS "nearest_dist_m"
    FROM pop_hosp_dist
    GROUP BY "geo_id", "population"
)

SELECT
    "population"                         -- population of the farthest grid cell
FROM pop_with_min_dist
ORDER BY "nearest_dist_m" DESC NULLS LAST, "geo_id"
LIMIT 1;