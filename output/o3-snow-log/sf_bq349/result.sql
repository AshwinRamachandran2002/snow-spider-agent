WITH "boundaries" AS (
    SELECT
        COALESCE("osm_id","osm_way_id")                                                       AS "boundary_id",
        ST_SETSRID( ST_GEOMFROMWKB("geometry"), 4326)                                         AS "geom"   -- GEOMETRY SRID 4326
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES ,
         LATERAL FLATTEN(input => "all_tags") AS tag
    WHERE "feature_type" = 'multipolygons'
      AND tag.value:"key"::string   = 'boundary'
      AND tag.value:"value"::string = 'administrative'
      AND "geometry" IS NOT NULL
),
"amenity_nodes" AS (
    SELECT
        ST_SETSRID( TO_GEOMETRY( ST_POINT("longitude"::double , "latitude"::double) ), 4326) AS "geom"   -- GEOMETRY SRID 4326
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES ,
         LATERAL FLATTEN(input => "all_tags") AS tag
    WHERE tag.value:"key"::string = 'amenity'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),
"boundary_counts" AS (
    SELECT
        b."boundary_id",
        COUNT(*) AS "amenity_cnt"
    FROM "boundaries" b
    JOIN "amenity_nodes" n
      ON ST_CONTAINS(b."geom", n."geom")
    GROUP BY b."boundary_id"
),
"median_calc" AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "amenity_cnt") AS "median_cnt"
    FROM "boundary_counts"
),
"diffs" AS (
    SELECT
        bc."boundary_id",
        bc."amenity_cnt",
        ABS(bc."amenity_cnt" - mc."median_cnt") AS "diff"
    FROM "boundary_counts" bc
    CROSS JOIN "median_calc" mc
)
SELECT "boundary_id"
FROM "diffs"
ORDER BY "diff" ASC NULLS LAST, "boundary_id"
LIMIT 1;