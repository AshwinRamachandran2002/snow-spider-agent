/*  Population of the 1-km Singapore grid cell that is farthest from any
    hospital (layer_code = 2110) or doctor (layer_code = 2120) POI            */

WITH latest_vintage AS (                    -- latest population vintage (<2023)
    SELECT MAX("last_updated") AS dt
    FROM   "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM"
    WHERE  "alpha_3_code" = 'SGP'
      AND  "last_updated" < '2023-01-01'
),

/* Singapore grid cells for that vintage, plus centroid */
cells AS (
    SELECT  TO_GEOGRAPHY("geog")                AS cell_geog,
            ST_CENTROID(TO_GEOGRAPHY("geog"))   AS cell_pt,
            "population"
    FROM    "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM",
            latest_vintage
    WHERE   "alpha_3_code" = 'SGP'
      AND   "last_updated" = latest_vintage.dt
),

/* Bounding box around Singapore, built from centroid extremes */
limits AS (
    SELECT  MIN("longitude_centroid") AS min_lon,
            MAX("longitude_centroid") AS max_lon,
            MIN("latitude_centroid")  AS min_lat,
            MAX("latitude_centroid")  AS max_lat
    FROM    "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM",
            latest_vintage
    WHERE   "alpha_3_code" = 'SGP'
      AND   "last_updated" = latest_vintage.dt
),
bbox AS (
    SELECT TO_GEOGRAPHY(
             'POLYGON((' ||
               min_lon || ' ' || min_lat || ',' ||
               min_lon || ' ' || max_lat || ',' ||
               max_lon || ' ' || max_lat || ',' ||
               max_lon || ' ' || min_lat || ',' ||
               min_lon || ' ' || min_lat ||
             '))'
           ) AS sg_bbox
    FROM limits
),

/* Hospital / doctor POIs inside that bounding box */
hospitals AS (
    SELECT  TO_GEOGRAPHY(pl."geometry") AS hosp_geog
    FROM    "GEO_OPENSTREETMAP_WORLDPOP"."GEO_OPENSTREETMAP"."PLANET_LAYERS" pl,
            bbox
    WHERE   pl."layer_code" IN (2110, 2120)
      AND   ST_INTERSECTS(TO_GEOGRAPHY(pl."geometry"), bbox.sg_bbox)
),

/* Distance from each grid cell to its nearest hospital / doctor */
dist_per_cell AS (
    SELECT  c."population",
            MIN( ST_DISTANCE(c.cell_pt, h.hosp_geog) ) AS nearest_dist_m
    FROM    cells      AS c
    CROSS JOIN hospitals AS h
    GROUP BY
            -- use population plus centroid WKT (text) to group uniquely
            c."population",
            ST_ASWKT(c.cell_pt)
)

/* Return population of the cell farthest from any hospital / doctor */
SELECT  "population"
FROM    dist_per_cell
ORDER BY nearest_dist_m DESC NULLS LAST
LIMIT 1;