WITH boundaries AS (
    SELECT DISTINCT
        COALESCE(p."osm_id", p."osm_way_id")                    AS boundary_id,
        ST_GEOGFROMWKB(p."geometry")                            AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES p,
         LATERAL FLATTEN ( INPUT => p."all_tags") t
    WHERE p."feature_type" = 'multipolygons'
      AND p."geometry" IS NOT NULL
      AND t.value:"key"::string  = 'boundary'
      AND LOWER(t.value:"value"::string) = 'administrative'
),
amenity_nodes AS (
    SELECT
        ST_POINT( CAST(n."longitude" AS DOUBLE),
                  CAST(n."latitude"  AS DOUBLE) )               AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES n,
         LATERAL FLATTEN ( INPUT => n."all_tags") t
    WHERE n."latitude"  IS NOT NULL
      AND n."longitude" IS NOT NULL
      AND t.value:"key"::string = 'amenity'
),
boundary_counts AS (
    SELECT
        b.boundary_id,
        COUNT(n.geog)                                           AS amenity_count
    FROM boundaries b
    LEFT JOIN amenity_nodes n
           ON ST_CONTAINS(b.geog, n.geog)
    GROUP BY b.boundary_id
),
median_val AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amenity_count) AS median_count
    FROM boundary_counts
)
SELECT boundary_id
FROM   boundary_counts, median_val
ORDER  BY ABS(boundary_counts.amenity_count - median_val.median_count) ASC,
          boundary_id
LIMIT 1;