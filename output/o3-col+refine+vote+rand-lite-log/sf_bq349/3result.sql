WITH admin_boundaries AS (                 -- all administrative multipolygons
    SELECT
        COALESCE(pf."osm_way_id", pf."osm_id") AS "boundary_id",
        pf."geometry"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::STRING   = 'boundary'
      AND tag.value:"value"::STRING = 'administrative'
),
amenity_nodes AS (                         -- amenity-tagged POIs (points only)
    SELECT
        pn."id",
        pn."geometry"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn,
         LATERAL FLATTEN(input => pn."all_tags") tag
    WHERE pn."geometry" IS NOT NULL
      AND tag.value:"key"::STRING = 'amenity'
),
boundary_counts AS (                       -- amenity count for every boundary
    SELECT
        ab."boundary_id",
        COUNT(an."id") AS "amenity_cnt"
    FROM admin_boundaries ab
    LEFT JOIN amenity_nodes an
      ON ST_CONTAINS(                      -- point falls inside the boundary
           TO_GEOGRAPHY(ab."geometry"),
           TO_GEOGRAPHY(an."geometry")
         )
    GROUP BY ab."boundary_id"
),
median_val AS (                            -- median of all counts
    SELECT APPROX_PERCENTILE("amenity_cnt", 0.50) AS "med_cnt"
    FROM boundary_counts
),
ranked AS (                                -- distance of every boundary to median
    SELECT
        bc."boundary_id",
        bc."amenity_cnt",
        ABS(bc."amenity_cnt" - mv."med_cnt") AS "diff_to_median"
    FROM boundary_counts bc
    CROSS JOIN median_val mv
)
SELECT "boundary_id"                       -- boundary closest to the median
FROM ranked
ORDER BY "diff_to_median" ASC,
         "boundary_id"      ASC           -- stable tie-breaker
LIMIT 1;