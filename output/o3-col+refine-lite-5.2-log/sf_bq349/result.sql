WITH admin_bounds AS (     -- all administrative multipolygons
    SELECT  COALESCE(pf."osm_way_id", pf."osm_id")         AS "boundary_id",
            pf."geometry"
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
            LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE   pf."feature_type"     = 'multipolygons'
      AND   tag.value:"key"::STRING   = 'boundary'
      AND   tag.value:"value"::STRING = 'administrative'
),

amen_nodes AS (            -- every node tagged with amenity=*
    SELECT  ST_MAKEPOINT(pn."longitude", pn."latitude")    AS "pt_geo"
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn,
            LATERAL FLATTEN (INPUT => pn."all_tags") tag
    WHERE   tag.value:"key"::STRING = 'amenity'
),

per_boundary AS (          -- count of amenity nodes per boundary
    SELECT  ab."boundary_id",
            COUNT(*)                       AS "amenity_cnt"
    FROM    admin_bounds  ab
    JOIN    amen_nodes    an
          ON ST_CONTAINS( TO_GEOGRAPHY(ab."geometry"),
                          TO_GEOGRAPHY(an."pt_geo") )
    GROUP BY ab."boundary_id"
),

stats AS (                 -- median of those counts
    SELECT  APPROX_PERCENTILE("amenity_cnt", 0.5) AS "median_cnt"
    FROM    per_boundary
)

SELECT  pb."boundary_id"      AS "ADMIN_BOUNDARY_OSM_ID"
FROM    per_boundary pb
CROSS JOIN stats s
ORDER BY ABS(pb."amenity_cnt" - s."median_cnt") ASC,   -- closest to median
         pb."boundary_id" ASC                          -- tie‑breaker
LIMIT 1;