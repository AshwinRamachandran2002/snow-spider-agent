/* 1) latest (before 2023‑01‑01) 1 km population grid for Singapore           */
/* 2) bounding envelope of all grid‑cell centroids                            */
/* 3) hospitals (layer_code 2110,2120) that fall inside that envelope         */
/* 4) distance from every grid cell to its nearest hospital                   */
/* 5) population of the grid cell farthest from any hospital                  */
WITH pop AS (          -- Most‑recent record per grid‑cell
    SELECT  "geo_id",
            "population",
            ST_POINT("longitude_centroid" , "latitude_centroid") AS centroid
    FROM    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM
    WHERE   "alpha_3_code" = 'SGP'
      AND   "last_updated" < '2023-01-01'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "geo_id"
                               ORDER BY "last_updated" DESC) = 1
),
hull AS (               -- Bounding region (axis‑aligned envelope) of all centroids
    SELECT ST_ENVELOPE( ST_COLLECT(centroid) ) AS region
    FROM   pop
),
hospitals AS (          -- Hospitals inside that region
    SELECT  TO_GEOGRAPHY("geometry") AS geom
    FROM    GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS , hull
    WHERE   "layer_code" IN (2110, 2120)
      AND   ST_INTERSECTS( TO_GEOGRAPHY("geometry"), hull.region )
),
distances AS (          -- Distance from each grid cell to nearest hospital
    SELECT  p."geo_id",
            p."population",
            MIN( ST_DISTANCE( p.centroid , h.geom ) ) AS min_dist
    FROM    pop                AS p
    CROSS JOIN hospitals       AS h
    GROUP BY p."geo_id", p."population"
)
SELECT  "population"
FROM    distances
ORDER BY min_dist DESC NULLS LAST, "geo_id"
LIMIT 1;