WITH boundaries AS (
    SELECT DISTINCT pf."osm_id", pf."geometry"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" pf,
         LATERAL FLATTEN(input => pf."all_tags") f
    WHERE pf."feature_type" = 'multipolygons'
      AND f.value:"key"::STRING = 'boundary'
      AND f.value:"value"::STRING = 'administrative'
),
pois AS (
    SELECT DISTINCT pn."id", pn."geometry"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_NODES" pn,
         LATERAL FLATTEN(input => pn."all_tags") f
    WHERE f.value:"key"::STRING = 'amenity'
),
boundary_poi_counts AS (
    SELECT b."osm_id", COUNT(*) AS poi_count
    FROM boundaries b
    JOIN pois p ON ST_CONTAINS(TO_GEOGRAPHY(b."geometry"), TO_GEOGRAPHY(p."geometry"))
    GROUP BY b."osm_id"
),
median_poi_count AS (
    SELECT MEDIAN(poi_count) AS median_count FROM boundary_poi_counts
)
SELECT bpc."osm_id"
FROM boundary_poi_counts bpc, median_poi_count mpc
ORDER BY ABS(bpc.poi_count - mpc.median_count) ASC, bpc."osm_id" ASC
LIMIT 1;