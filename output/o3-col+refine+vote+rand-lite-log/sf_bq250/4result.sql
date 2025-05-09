WITH sg_grid_raw AS (      -- All pre-2023 Singapore 1-km grid rows
    SELECT
        "geo_id",
        "population",
        "last_updated",
        ST_POINT("longitude_centroid","latitude_centroid") AS geom          -- GEOGRAPHY
    FROM "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM"
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
), sg_grid AS (            -- Latest record per cell
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY "geo_id"
                                ORDER BY "last_updated" DESC) AS rn
        FROM sg_grid_raw
    )
    WHERE rn = 1
), bbox AS (               -- Bounding rectangle for all centroids
    SELECT ST_ENVELOPE(ST_COLLECT(geom)) AS hull
    FROM   sg_grid
), hospitals AS (          -- OSM hospitals / doctors inside bounding box
    SELECT
        ST_CENTROID(ST_GEOGFROMWKB(l."geometry")) AS geom
    FROM "GEO_OPENSTREETMAP_WORLDPOP"."GEO_OPENSTREETMAP"."PLANET_LAYERS" l,
         bbox
    WHERE l."layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(ST_GEOGFROMWKB(l."geometry"), bbox.hull)
), grid_dist AS (          -- Distance from each grid cell to nearest hospital
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(g.geom, h.geom)) AS nearest_hosp_dist_m
    FROM sg_grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
), farthest AS (           -- Cell farthest from any hospital
    SELECT *
    FROM   grid_dist
    ORDER BY nearest_hosp_dist_m DESC NULLS LAST
    LIMIT 1
)
SELECT "population"
FROM   farthest;