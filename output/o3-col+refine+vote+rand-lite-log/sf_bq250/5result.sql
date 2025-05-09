WITH latest_snapshot AS (   -- most recent WorldPop 1-km grid before 2023-01-01
    SELECT MAX("last_updated") AS snap_date
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" < '2023-01-01'
),
sgp_cells AS (              -- Singapore grid cells + their centroids
    SELECT
        "geo_id",
        "population",
        TO_GEOGRAPHY("geog")                AS cell_geom,
        ST_CENTROID(TO_GEOGRAPHY("geog"))   AS centroid_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE "alpha_3_code" = 'SGP'
      AND "last_updated" = (SELECT snap_date FROM latest_snapshot)
),
sgp_bbox AS (               -- bounding rectangle around all centroids
    SELECT ST_ENVELOPE(ST_UNION_AGG(centroid_geom)) AS bbox_geom
    FROM sgp_cells
),
hospitals AS (              -- OSM hospitals / doctors within the bbox
    SELECT TO_GEOGRAPHY(pl."geometry") AS hosp_geom
    FROM GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS pl,
         sgp_bbox b
    WHERE pl."layer_code" IN (2110, 2120)
      AND ST_INTERSECTS(TO_GEOGRAPHY(pl."geometry"), b.bbox_geom)
),
distances AS (              -- nearest-hospital distance (metres) per grid cell
    SELECT
        c."geo_id",
        c."population",
        MIN(ST_DISTANCE(c.centroid_geom, h.hosp_geom)) AS nearest_hospital_m
    FROM sgp_cells  c
    CROSS JOIN hospitals h
    GROUP BY c."geo_id", c."population"
),
farthest_cell AS (          -- cell farthest from any hospital
    SELECT *
    FROM distances
    ORDER BY nearest_hospital_m DESC NULLS LAST
    LIMIT 1
)
SELECT "population"
FROM farthest_cell;