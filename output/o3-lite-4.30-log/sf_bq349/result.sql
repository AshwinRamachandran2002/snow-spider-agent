WITH admin_bounds AS (
    SELECT
        COALESCE("osm_id", "osm_way_id") AS "osm_id",
        TO_GEOGRAPHY("geometry")         AS "geom"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES",
         LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE "feature_type" = 'multipolygons'
      AND tag.value:"key"::STRING   = 'boundary'
      AND tag.value:"value"::STRING = 'administrative'
),
amenity_nodes AS (
    SELECT
        COALESCE(
            TO_GEOGRAPHY("geometry"),
            ST_MAKEPOINT("longitude"::DOUBLE, "latitude"::DOUBLE)
        ) AS "geom"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_NODES",
         LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE tag.value:"key"::STRING = 'amenity'
),
amenity_count_per_boundary AS (
    SELECT
        ab."osm_id",
        COUNT(an."geom") AS "amenity_cnt"
    FROM admin_bounds ab
    LEFT JOIN amenity_nodes an
      ON ST_CONTAINS(ab."geom", an."geom")
    GROUP BY ab."osm_id"
),
median_val AS (
    SELECT MEDIAN("amenity_cnt") AS "med_cnt"
    FROM amenity_count_per_boundary
),
ranked AS (
    SELECT
        ac."osm_id",
        ROW_NUMBER() OVER (
            ORDER BY ABS(ac."amenity_cnt" - mv."med_cnt"), ac."osm_id"
        ) AS "rn"
    FROM amenity_count_per_boundary ac
    CROSS JOIN median_val mv
)
SELECT "osm_id"
FROM ranked
WHERE "rn" = 1;