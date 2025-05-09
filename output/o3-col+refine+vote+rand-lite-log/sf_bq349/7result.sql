WITH boundaries AS (   -- all administrative boundaries stored as multipolygons
    SELECT  pf."osm_id",
            TO_GEOGRAPHY(pf."geometry") AS "geom"
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf,
            LATERAL FLATTEN (INPUT => TRY_PARSE_JSON(pf."all_tags")) tag
    WHERE   pf."feature_type" = 'multipolygons'
      AND   tag.value:"key"::STRING   = 'boundary'
      AND   tag.value:"value"::STRING = 'administrative'
),  
amenity_nodes AS (     -- every node that owns an amenity tag
    SELECT  ST_MAKEPOINT(n."longitude"::DOUBLE,
                         n."latitude" ::DOUBLE) AS "pt"
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" n,
            LATERAL FLATTEN (INPUT => TRY_PARSE_JSON(n."all_tags")) tag
    WHERE   tag.value:"key"::STRING = 'amenity'
      AND   n."latitude"  IS NOT NULL
      AND   n."longitude" IS NOT NULL
),
boundary_counts AS (   -- POI count per boundary
    SELECT  b."osm_id",
            COUNT(a."pt") AS "amenity_cnt"
    FROM    boundaries b
    LEFT JOIN amenity_nodes a
           ON ST_CONTAINS(b."geom", a."pt")
    GROUP BY b."osm_id"
),
median_val AS (        -- median of all amenity counts
    SELECT  APPROX_PERCENTILE("amenity_cnt", 0.5) AS "med"
    FROM    boundary_counts
),
ranked AS (            -- distance to median & ranking
    SELECT  bc."osm_id",
            bc."amenity_cnt",
            ABS(bc."amenity_cnt" - mv."med") AS "dist_to_median",
            ROW_NUMBER() OVER (ORDER BY ABS(bc."amenity_cnt" - mv."med"),
                                        bc."amenity_cnt") AS "rn"
    FROM    boundary_counts bc,
            median_val     mv
)
SELECT  "osm_id"
FROM    ranked
WHERE   "rn" = 1;