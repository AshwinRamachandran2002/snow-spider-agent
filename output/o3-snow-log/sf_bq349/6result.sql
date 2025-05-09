WITH boundaries AS (   -- all administrative boundaries stored as multipolygons
    SELECT DISTINCT
           COALESCE(pf."osm_id", pf."osm_way_id")            AS boundary_id,
           ST_GEOGFROMWKB(pf."geometry")                     AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN ( INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"  = 'boundary'
      AND tag.value:"value" = 'administrative'
      AND pf."geometry" IS NOT NULL
),
amenity_nodes AS (      -- every node tagged with “amenity=…”
    SELECT
           pn."id"                                            AS node_id,
           ST_POINT( CAST(pn."longitude" AS DOUBLE)
                   , CAST(pn."latitude"  AS DOUBLE) )         AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn ,
         LATERAL FLATTEN ( INPUT => pn."all_tags") tag
    WHERE tag.value:"key" = 'amenity'
      AND pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
),
boundary_counts AS (    -- count amenity POIs inside every boundary
    SELECT
           b.boundary_id,
           COUNT(an.node_id) AS amenity_count
    FROM boundaries b
    LEFT JOIN amenity_nodes an
           ON ST_CONTAINS(b.geog, an.geog)
    GROUP BY b.boundary_id
),
median_val AS (         -- median of all counts
    SELECT MEDIAN(amenity_count) AS med_cnt
    FROM boundary_counts
)
SELECT boundary_id      -- boundary whose count is closest to that median
FROM boundary_counts, median_val
ORDER BY ABS(amenity_count - med_cnt) ASC, boundary_id
LIMIT 1;