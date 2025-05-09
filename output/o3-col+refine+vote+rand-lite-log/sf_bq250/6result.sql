WITH latest_vintage AS (              -- most recent WORLDPOP vintage before 2023-01-01
    SELECT MAX("last_updated") AS "last_updated"
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),
cells AS (                            -- 1-km grid cells for that vintage
    SELECT
        "geo_id",
        "population",
        ST_POINT("longitude_centroid","latitude_centroid") AS c_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (SELECT "last_updated" FROM latest_vintage)
),
hull AS (                             -- bounding polygon around all centroids
    SELECT ST_ENVELOPE(
             ST_UNION_AGG(c_geom)
           ) AS hull_geom
    FROM cells
),
hospitals AS (                        -- OSM hospitals/clinics inside that polygon
    SELECT ST_GEOGFROMWKB("geometry") AS h_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS, hull
    WHERE "layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(ST_GEOGFROMWKB("geometry"), hull.hull_geom)
),
distances AS (                        -- distance from each cell to its nearest hospital
    SELECT
        c."geo_id",
        c."population",
        MIN(ST_DISTANCE(c.c_geom, h.h_geom)) AS nearest_hospital_m
    FROM cells     c
    JOIN hospitals h ON TRUE
    GROUP BY c."geo_id", c."population"
),
farthest_cell AS (                    -- cell farthest from any hospital
    SELECT *
    FROM distances
    ORDER BY nearest_hospital_m DESC NULLS LAST
    LIMIT 1
)
SELECT "population"
FROM farthest_cell;