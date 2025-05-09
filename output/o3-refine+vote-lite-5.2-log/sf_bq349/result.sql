WITH "boundaries" AS (      -- administrative boundaries (multipolygons)
    SELECT DISTINCT
        COALESCE("osm_id", "osm_way_id")        AS "boundary_osm_id",
        TO_GEOGRAPHY("geometry")                AS "geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
         ,LATERAL FLATTEN(INPUT => "all_tags") f      -- tag array → rows
    WHERE "feature_type" = 'multipolygons'
      AND "geometry" IS NOT NULL
      AND f.value:"key"::string  = 'boundary'
      AND LOWER(f.value:"value"::string) = 'administrative'
),
"poi_nodes" AS (            -- points of interest with amenity tag
    SELECT DISTINCT
        "id"                                   AS "node_id",
        ST_MAKEPOINT("longitude","latitude")   AS "geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES
         ,LATERAL FLATTEN(INPUT => "all_tags") t
    WHERE "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
      AND t.value:"key"::string = 'amenity'
),
"counts" AS (               -- amenity count per boundary
    SELECT
        b."boundary_osm_id",
        COUNT(*)                      AS "amenity_cnt"
    FROM "boundaries" b
    JOIN "poi_nodes" n
      ON ST_CONTAINS(b."geom", n."geom")
    GROUP BY b."boundary_osm_id"
),
"median_val" AS (
    SELECT MEDIAN("amenity_cnt") AS "median_cnt" FROM "counts"
),
"ranked" AS (
    SELECT
        c."boundary_osm_id",
        ROW_NUMBER() OVER (
            ORDER BY
                ABS(c."amenity_cnt" - m."median_cnt"),
                c."boundary_osm_id"
        ) AS "rn"
    FROM "counts" c
    CROSS JOIN "median_val" m
)
SELECT "boundary_osm_id"
FROM   "ranked"
WHERE  "rn" = 1;