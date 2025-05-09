WITH admin_boundaries AS (          -- administrative multipolygon ways
    SELECT DISTINCT
           pf."osm_way_id"                              AS boundary_id,
           TO_GEOGRAPHY(pf."geometry")                 AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf
         ,LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND pf."geometry" IS NOT NULL
      AND tag.value:"key"::STRING   = 'boundary'
      AND tag.value:"value"::STRING = 'administrative'
),
amenity_nodes AS (              -- nodes that carry an amenity tag
    SELECT
           pn."id"                                                AS node_id,
           ST_MAKEPOINT(pn."longitude"::FLOAT,
                        pn."latitude" ::FLOAT)                   AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
         ,LATERAL FLATTEN(input => pn."all_tags") tag
    WHERE tag.value:"key"::STRING = 'amenity'
      AND pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
),
boundary_counts AS (            -- count amenity nodes per boundary
    SELECT
           ab.boundary_id,
           COUNT(an.node_id)                      AS amenity_cnt
    FROM admin_boundaries ab
    LEFT JOIN amenity_nodes an
           ON ST_CONTAINS(ab.geom, an.geom)
    GROUP BY ab.boundary_id
),
median_stat AS (                -- median of those counts
    SELECT MEDIAN(amenity_cnt) AS median_cnt
    FROM   boundary_counts
)
SELECT bc.boundary_id
FROM   boundary_counts bc
JOIN   median_stat ms ON 1=1
ORDER  BY ABS(bc.amenity_cnt - ms.median_cnt) ASC,
          bc.boundary_id
LIMIT 1;