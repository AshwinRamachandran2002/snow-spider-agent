WITH grid_raw AS (   -- Singapore 1-km grids before 2023-01-01
    SELECT  "geo_id",
            "population",
            "longitude_centroid",
            "latitude_centroid",
            "last_updated"
    FROM    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE   "alpha_3_code" = 'SGP'
      AND   "last_updated" < '2023-01-01'
),
latest_vintage AS (  -- most-recent vintage (<2023-01-01)
    SELECT MAX("last_updated") AS last_dt
    FROM   grid_raw
),
grid AS (            -- grid cells of that vintage, create centroid geography
    SELECT  g."geo_id",
            g."population",
            ST_POINT(g."longitude_centroid", g."latitude_centroid") AS centroid_geog
    FROM    grid_raw g
    JOIN    latest_vintage v
      ON    g."last_updated" = v.last_dt
),
bbox AS (            -- bounding region of all centroids (axis-aligned envelope)
    SELECT ST_ENVELOPE(ST_COLLECT(centroid_geog)) AS region_geog
    FROM   grid
),
hospitals AS (       -- hospitals inside that bounding region
    SELECT ST_GEOGFROMWKB("geometry") AS hosp_geog
    FROM   GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS pl
    JOIN   bbox b
      ON   ST_INTERSECTS(ST_GEOGFROMWKB(pl."geometry"), b.region_geog)
    WHERE  pl."layer_code" IN (2110, 2120)
),
grid_dist AS (       -- distance from each grid cell to nearest hospital
    SELECT  g."geo_id",
            g."population",
            MIN(ST_DISTANCE(g.centroid_geog, h.hosp_geog)) AS nearest_dist
    FROM    grid g
    CROSS JOIN hospitals h
    GROUP BY g."geo_id", g."population"
),
farthest_cell AS (   -- grid cell farthest from any hospital
    SELECT *
    FROM   grid_dist
    ORDER BY nearest_dist DESC NULLS LAST
    LIMIT 1
)
SELECT "population"
FROM   farthest_cell;