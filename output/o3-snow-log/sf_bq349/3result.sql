WITH boundaries AS (
    SELECT DISTINCT
           COALESCE("osm_id","osm_way_id")                                AS boundary_id ,
           ST_GEOGFROMWKB("geometry")                                     AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
         LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE "feature_type" = 'multipolygons'
      AND "geometry" IS NOT NULL
      AND COALESCE("osm_id","osm_way_id") IS NOT NULL
      AND tag.value:"key"   = 'boundary'
      AND tag.value:"value" = 'administrative'
),
pois AS (
    SELECT ST_GEOGFROMWKB("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS,
         LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE "geometry" IS NOT NULL
      AND tag.value:"key" = 'amenity'
),
boundary_counts AS (
    SELECT b.boundary_id,
           COUNT(p.geom) AS poi_count
    FROM boundaries b
    LEFT JOIN pois p
      ON ST_CONTAINS(b.geom , p.geom)
    GROUP BY b.boundary_id
),
median_val AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY poi_count) AS med
    FROM boundary_counts
)
SELECT boundary_id
FROM (
      SELECT bc.boundary_id,
             ABS(bc.poi_count - mv.med) AS diff
      FROM boundary_counts bc
      CROSS JOIN median_val mv
)
ORDER BY diff ASC NULLS LAST, boundary_id
LIMIT 1;