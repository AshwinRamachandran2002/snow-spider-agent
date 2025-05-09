WITH admin_boundaries AS (                         -- all admin boundaries (multipolygons)
    SELECT
        pf."osm_id",
        TO_GEOGRAPHY(pf."geometry") AS geom
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf,
         LATERAL FLATTEN(INPUT => pf."all_tags") pf_tag
    WHERE pf."feature_type" = 'multipolygons'
      AND pf_tag.value:"key"::STRING   = 'boundary'
      AND pf_tag.value:"value"::STRING = 'administrative'
      AND pf."geometry" IS NOT NULL
),
amenity_nodes AS (                                -- every node tagged with amenity=*
    SELECT
        n."id",
        ST_MAKEPOINT(
            TO_DOUBLE(n."longitude"),
            TO_DOUBLE(n."latitude")
        ) AS geom
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_NODES" n,
         LATERAL FLATTEN(INPUT => n."all_tags") n_tag
    WHERE n_tag.value:"key"::STRING = 'amenity'
),
amenity_counts AS (                               -- count amenity nodes inside each boundary
    SELECT
        ab."osm_id",
        COUNT(an."id") AS amenity_cnt
    FROM admin_boundaries ab
    LEFT JOIN amenity_nodes an
           ON ST_CONTAINS(ab.geom, an.geom)
    GROUP BY ab."osm_id"
),
median_val AS (                                   -- median of all counts
    SELECT MEDIAN(amenity_cnt) AS med
    FROM   amenity_counts
)
SELECT ac."osm_id"
FROM   amenity_counts ac, median_val m
ORDER  BY ABS(ac.amenity_cnt - m.med), ac."osm_id"
LIMIT 1;