WITH "BOUNDARIES" AS (
    SELECT
        pf."osm_id",
        pf."osm_way_id",
        TO_GEOGRAPHY(pf."geometry") AS "geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"   = 'boundary'
      AND tag.value:"value" = 'administrative'
      AND pf."geometry" IS NOT NULL
),
"POIS" AS (
    SELECT
        pn."id",
        COALESCE(
            TO_GEOGRAPHY(pn."geometry"),
            ST_MAKEPOINT(pn."longitude", pn."latitude")
        ) AS "geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn,
         LATERAL FLATTEN(INPUT => pn."all_tags") tag
    WHERE tag.value:"key" = 'amenity'
      AND (
           pn."geometry" IS NOT NULL
        OR (pn."longitude" IS NOT NULL AND pn."latitude" IS NOT NULL)
      )
),
"COUNTS" AS (
    SELECT
        b."osm_id",
        b."osm_way_id",
        COUNT(*) AS "poi_cnt"
    FROM "BOUNDARIES" b
    JOIN "POIS" p
      ON ST_CONTAINS(b."geom", p."geom")
    GROUP BY b."osm_id", b."osm_way_id"
),
"MEDIAN_VAL" AS (
    SELECT MEDIAN("poi_cnt") AS "median_cnt"
    FROM "COUNTS"
),
"TARGET" AS (
    SELECT
        COALESCE(c."osm_id", c."osm_way_id") AS "osm_id",
        ABS(c."poi_cnt" - m."median_cnt")    AS "diff_from_median"
    FROM "COUNTS" c
    CROSS JOIN "MEDIAN_VAL" m
    ORDER BY "diff_from_median" ASC, c."poi_cnt" ASC, COALESCE(c."osm_id", c."osm_way_id") ASC
    LIMIT 1
)
SELECT "osm_id"
FROM "TARGET";