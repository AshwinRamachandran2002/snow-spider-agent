WITH admin_boundaries AS (   -- administrative multipolygon boundaries
    SELECT DISTINCT
           COALESCE("osm_id","osm_way_id")              AS boundary_id,
           TO_GEOGRAPHY("geometry")                     AS boundary_geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
         , LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE "feature_type" = 'multipolygons'
      AND tag.value:"key"::string   = 'boundary'
      AND tag.value:"value"::string = 'administrative'
      AND "geometry" IS NOT NULL
),
amenity_nodes AS (          -- POIs that have an amenity tag
    SELECT
           ST_MAKEPOINT(CAST("longitude" AS DOUBLE),
                        CAST("latitude"  AS DOUBLE))    AS node_geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES
         , LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
      AND tag.value:"key"::string = 'amenity'
),
boundary_counts AS (        -- count amenity nodes inside each boundary
    SELECT b.boundary_id,
           COUNT(*) AS amenity_cnt
    FROM   admin_boundaries b
    JOIN   amenity_nodes  n
      ON   ST_CONTAINS(b.boundary_geog , n.node_geog)
    GROUP  BY b.boundary_id
),
median_val AS (             -- overall median of the counts
    SELECT PERCENTILE_CONT(0.5)
           WITHIN GROUP (ORDER BY amenity_cnt) AS median_cnt
    FROM   boundary_counts
),
ranked AS (                  -- deviation from the median
    SELECT bc.boundary_id,
           bc.amenity_cnt,
           mv.median_cnt,
           ABS(bc.amenity_cnt - mv.median_cnt) AS diff_from_median
    FROM   boundary_counts bc
    CROSS  JOIN median_val  mv
)
SELECT boundary_id
FROM   ranked
ORDER  BY diff_from_median ASC NULLS LAST,
          boundary_id
LIMIT 1;