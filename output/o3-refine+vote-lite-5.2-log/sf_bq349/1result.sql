WITH boundaries AS (  /* administrative multipolygon boundaries */
    SELECT DISTINCT
           COALESCE(pf."osm_way_id", pf."osm_id")          AS boundary_id,
           ST_GEOGFROMWKB(pf."geometry")                  AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND pf."geometry"    IS NOT NULL
      AND tag.value:"key"  = 'boundary'
      AND LOWER(tag.value:"value") = 'administrative'
),
amenity_nodes AS (      /* POIs that carry an amenity tag */
    SELECT DISTINCT
           pn."id"                                         AS node_id,
           ST_MAKEPOINT(
               CAST(pn."longitude" AS DOUBLE),
               CAST(pn."latitude"  AS DOUBLE)
           )                                               AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn,
         LATERAL FLATTEN(input => pn."all_tags") tag
    WHERE pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
      AND tag.value:"key" = 'amenity'
),
node_counts AS (        /* number of amenity POIs per boundary */
    SELECT
        b.boundary_id,
        COUNT(n.node_id) AS amenity_count
    FROM boundaries b
    LEFT JOIN amenity_nodes n
           ON ST_CONTAINS(b.geom , n.geom)
    GROUP BY b.boundary_id
),
stats AS (              /* median of those counts */
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amenity_count) AS median_cnt
    FROM node_counts
),
ranked AS (
    SELECT
        nc.boundary_id,
        ABS(nc.amenity_count - s.median_cnt) AS diff
    FROM node_counts nc
    CROSS JOIN stats s
)
SELECT boundary_id
FROM ranked
ORDER BY diff, boundary_id
LIMIT 1;