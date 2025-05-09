/* Return the population of the Singapore 1-km grid cell (latest vintage before 2023)
   that is farthest from any OSM hospital / doctor feature (layer_code 2110, 2120). */
WITH latest_vintage AS (
    SELECT MAX("last_updated") AS "dt"
    FROM   GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE  "alpha_3_code" = 'SGP'
      AND  "last_updated" < '2023-01-01'
),
sg_cells AS (
    SELECT  "geo_id",
            "population",
            "longitude_centroid"  AS "lon",
            "latitude_centroid"   AS "lat"
    FROM    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM c
    JOIN    latest_vintage v  ON c."last_updated" = v."dt"
    WHERE   c."alpha_3_code" = 'SGP'
),
extent AS (
    /* Bounding rectangle around all Singapore grid centroids */
    SELECT  MIN("lon") AS min_lon,
            MAX("lon") AS max_lon,
            MIN("lat") AS min_lat,
            MAX("lat") AS max_lat
    FROM    sg_cells
),
bbox AS (
    SELECT TO_GEOGRAPHY(
             'POLYGON((' ||
               min_lon || ' ' || min_lat || ',' ||
               max_lon || ' ' || min_lat || ',' ||
               max_lon || ' ' || max_lat || ',' ||
               min_lon || ' ' || max_lat || ',' ||
               min_lon || ' ' || min_lat || '))'
           ) AS poly
    FROM extent
),
hospitals AS (
    /* Hospitals & doctors that fall inside the bounding rectangle */
    SELECT  TO_GEOGRAPHY(pl."geometry") AS geom
    FROM    GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS pl,
            bbox
    WHERE   pl."layer_code" IN (2110, 2120)
      AND   ST_INTERSECTS( TO_GEOGRAPHY(pl."geometry"), bbox.poly )
),
distances AS (
    /* Distance from each grid centroid to its nearest hospital */
    SELECT  c."geo_id",
            c."population",
            MIN(
                ST_DISTANCE(
                  ST_POINT(c."lon", c."lat"),
                  ST_CENTROID(h.geom)
                )
            ) AS nearest_hosp_dist_m
    FROM    sg_cells c
    CROSS   JOIN hospitals h
    GROUP  BY c."geo_id", c."population"
)
SELECT "population"
FROM   distances
ORDER  BY nearest_hosp_dist_m DESC NULLS LAST
LIMIT  1;