WITH boundaries AS (    -- administrative multipolygon features
    SELECT DISTINCT
        pf."osm_id",
        TO_GEOGRAPHY(pf."geometry") AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:key::string = 'boundary'
      AND LOWER(tag.value:value::string) = 'administrative'
),
amenity_nodes AS (      -- POIs that have an amenity tag
    SELECT
        ST_MAKEPOINT(
            CAST(pn."longitude" AS DOUBLE),
            CAST(pn."latitude"  AS DOUBLE)
        ) AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn ,
         LATERAL FLATTEN( INPUT => pn."all_tags") tag
    WHERE pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
      AND tag.value:key::string = 'amenity'
),
boundary_counts AS (    -- number of amenity nodes inside each boundary
    SELECT
        b."osm_id",
        COUNT(*) AS amenity_poi_count
    FROM boundaries b
    JOIN amenity_nodes n
      ON ST_CONTAINS(b.geog , n.geog)
    GROUP BY b."osm_id"
),
stats AS (              -- median of the counts
    SELECT MEDIAN(amenity_poi_count) AS med_cnt
    FROM boundary_counts
),
ranked AS (             -- distance from median
    SELECT
        bc."osm_id",
        ABS(bc.amenity_poi_count - s.med_cnt) AS diff_from_med
    FROM boundary_counts bc
    CROSS JOIN stats s
)
SELECT "osm_id"
FROM ranked
ORDER BY diff_from_med ASC, "osm_id" ASC
LIMIT 1;