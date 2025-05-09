WITH admin_boundaries AS (   -- administrative boundaries stored as multipolygons
    SELECT
        COALESCE("osm_way_id","osm_id")                       AS admin_osm_id ,
        ST_GEOGFROMWKB("geometry")                            AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf ,
         LATERAL FLATTEN (INPUT => pf."all_tags")             tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::string  = 'boundary'
      AND LOWER(tag.value:"value"::string) = 'administrative'
      AND pf."geometry" IS NOT NULL
),

amenity_pois AS (            -- POIs with the "amenity" tag coming from planet_nodes
    SELECT
        pn."id"                                    AS node_id ,
        ST_MAKEPOINT(pn."longitude"::double ,
                     pn."latitude" ::double)       AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn ,
         LATERAL FLATTEN (INPUT => pn."all_tags")  tag
    WHERE tag.value:"key"::string = 'amenity'
      AND pn."latitude"  IS NOT NULL
      AND pn."longitude" IS NOT NULL
),

boundary_counts AS (         -- number of amenity POIs inside each boundary
    SELECT
        ab.admin_osm_id ,
        COUNT(ap.node_id)               AS amenity_cnt
    FROM admin_boundaries ab
         LEFT JOIN amenity_pois ap
               ON ST_CONTAINS(ab.geom , ap.geom)
    GROUP BY ab.admin_osm_id
),

median_val AS (              -- median of those counts
    SELECT MEDIAN(amenity_cnt) AS med_cnt
    FROM boundary_counts
)

SELECT bc.admin_osm_id
FROM   boundary_counts bc
       CROSS JOIN median_val mv
ORDER  BY ABS(bc.amenity_cnt - mv.med_cnt) ASC ,
          bc.admin_osm_id                  ASC   -- tie‑breaker
LIMIT  1;