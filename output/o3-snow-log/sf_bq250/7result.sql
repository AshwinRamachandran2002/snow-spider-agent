/*  Find the 1-km population-grid cell in Singapore (latest data before 2023-01-01)
    that is farthest from any hospital (layer_code 2110 or 2120)               */
WITH sgp_grid AS (       /* newest Singapore grid snapshot prior to 2023-01-01 */
    SELECT  "geo_id",
            "population",
            ST_MAKEPOINT("longitude_centroid","latitude_centroid") AS centroid_geog
    FROM    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE   "alpha_3_code" = 'SGP'
      AND   "last_updated" < DATE '2023-01-01'
    QUALIFY "last_updated" = MAX("last_updated") OVER ()          -- latest date
),
bounding_box AS (        /* simple rectangle covering all centroids            */
    SELECT ST_GEOGFROMTEXT(
             'POLYGON((' ||
             MIN(ST_X(centroid_geog)) || ' ' || MIN(ST_Y(centroid_geog)) || ', ' ||
             MIN(ST_X(centroid_geog)) || ' ' || MAX(ST_Y(centroid_geog)) || ', ' ||
             MAX(ST_X(centroid_geog)) || ' ' || MAX(ST_Y(centroid_geog)) || ', ' ||
             MAX(ST_X(centroid_geog)) || ' ' || MIN(ST_Y(centroid_geog)) || ', ' ||
             MIN(ST_X(centroid_geog)) || ' ' || MIN(ST_Y(centroid_geog)) || '))'
           ) AS hull_geog
    FROM   sgp_grid
),
hospitals AS (           /* OSM hospital geometries                            */
    SELECT TO_GEOGRAPHY("geometry") AS hosp_geog
    FROM   GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS
    WHERE  "layer_code" IN (2110, 2120)
),
hosp_in_sgp AS (         /* hospitals inside the bounding region               */
    SELECT h.hosp_geog
    FROM   hospitals h
    CROSS JOIN bounding_box b
    WHERE  ST_INTERSECTS(h.hosp_geog, b.hull_geog)
),
grid_nearest_dist AS (   /* distance (metres) from each grid cell to nearest hospital */
    SELECT  g."geo_id",
            g."population",
            MIN(ST_DISTANCE(g.centroid_geog, h.hosp_geog)) AS nearest_dist_m
    FROM    sgp_grid g
    CROSS JOIN hosp_in_sgp h
    GROUP BY g."geo_id", g."population"
),
farthest_cell AS (       /* grid cell farthest from any hospital               */
    SELECT *
    FROM   grid_nearest_dist
    ORDER BY nearest_dist_m DESC NULLS LAST
    LIMIT  1
)
SELECT "population"
FROM   farthest_cell;