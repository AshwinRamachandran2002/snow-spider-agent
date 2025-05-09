WITH boundaries AS (   -- administrative multipolygon boundaries
    SELECT
        COALESCE(pf."osm_id",pf."osm_way_id")     AS boundary_id ,
        TO_GEOGRAPHY(pf."geometry")               AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:key::string  = 'boundary'
      AND tag.value:value::string = 'administrative'
      AND pf."geometry" IS NOT NULL
      AND COALESCE(pf."osm_id",pf."osm_way_id") IS NOT NULL
), 

amenity_nodes AS (     -- nodes having an amenity tag
    SELECT
        pn."id"                                                     AS node_id ,
        TO_GEOGRAPHY('POINT ('|| pn."longitude" ||' '|| pn."latitude" ||')')  AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn ,
         LATERAL FLATTEN(input => pn."all_tags") tag
    WHERE tag.value:key::string = 'amenity'
      AND pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
), 

node_counts AS (        -- count amenity nodes inside each boundary
    SELECT
        b.boundary_id ,
        COUNT(*) AS amenity_count
    FROM boundaries b
    JOIN amenity_nodes n
      ON ST_CONTAINS(b.geom , n.geom)
    GROUP BY b.boundary_id
), 

median_val AS (         -- median of those counts
    SELECT MEDIAN(amenity_count) AS median_count
    FROM node_counts
), 

closest AS (            -- pick boundary whose count is closest to median
    SELECT
        nc.boundary_id ,
        ABS(nc.amenity_count - mv.median_count) AS diff ,
        ROW_NUMBER() OVER (ORDER BY ABS(nc.amenity_count - mv.median_count) ASC ,
                                   nc.boundary_id ASC) AS rn
    FROM node_counts nc
    CROSS JOIN median_val mv
)

SELECT boundary_id AS "osm_id"
FROM closest
WHERE rn = 1;