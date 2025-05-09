WITH admin_boundaries AS (        -- all administrative boundaries (multipolygons)
    SELECT DISTINCT
           pf."osm_way_id",
           ST_GEOGFROMWKB(pf."geometry")             AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
           LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE  pf."feature_type" = 'multipolygons'
      AND  tag.value:"key"::STRING   = 'boundary'
      AND  tag.value:"value"::STRING = 'administrative'
      AND  pf."osm_way_id" IS NOT NULL
),

amenity_nodes AS (               -- every POI node carrying an “amenity” tag
    SELECT DISTINCT
           pn."id",
           ST_MAKEPOINT(pn."longitude"::FLOAT , pn."latitude"::FLOAT) AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn ,
           LATERAL FLATTEN (INPUT => pn."all_tags") tag
    WHERE  tag.value:"key"::STRING = 'amenity'
),

boundary_cnt AS (                -- per-boundary amenity counts
    SELECT  ab."osm_way_id",
            COUNT(an."id") AS amenity_cnt
    FROM    admin_boundaries  ab
    LEFT JOIN amenity_nodes   an
      ON    ST_CONTAINS(ab.geom , an.geom)
    GROUP BY ab."osm_way_id"
),

stats AS (                       -- median of the counts
    SELECT MEDIAN(amenity_cnt) AS med
    FROM   boundary_cnt
),

ranked AS (                      -- distance of each boundary’s count to the median
    SELECT  bc."osm_way_id",
            bc.amenity_cnt,
            ABS(bc.amenity_cnt - s.med) AS dist_to_med,
            ROW_NUMBER() OVER (ORDER BY ABS(bc.amenity_cnt - s.med) ASC,
                                         bc."osm_way_id") AS rn
    FROM    boundary_cnt bc,
            stats        s
)

SELECT  "osm_way_id"
FROM    ranked
WHERE   rn = 1;