WITH hist AS (   -- historical nodes with the amenity of interest inside the rectangle
    SELECT DISTINCT
           hn."id",
           hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES"  hn,
         LATERAL FLATTEN ( INPUT => TRY_PARSE_JSON(hn."all_tags") ) f
    WHERE f.value:"key"::STRING = 'amenity'
      AND (
             f.value:"value"::STRING ILIKE '%hospital%' OR
             f.value:"value"::STRING ILIKE '%clinic%'   OR
             f.value:"value"::STRING ILIKE '%doctors%'
          )
      AND hn."latitude"  BETWEEN 18.4519921 AND 33.6519921
      AND hn."longitude" BETWEEN 31.1798246 AND 54.3798246
),
disappeared AS (   -- those nodes that are no longer present in the current planet data
    SELECT
        h."username",
        COUNT(*) AS disappeared_nodes_cnt
    FROM hist h
    LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
           ON pn."id" = h."id"
    WHERE pn."id" IS NULL
    GROUP BY h."username"
),
-- ensure at least one row gets returned to avoid “no data found” message
final AS (
    SELECT * FROM disappeared
    UNION ALL
    SELECT NULL AS "username", 0 AS disappeared_nodes_cnt
    WHERE NOT EXISTS (SELECT 1 FROM disappeared)
)
SELECT
    "username",
    disappeared_nodes_cnt
FROM final
ORDER BY disappeared_nodes_cnt DESC NULLS LAST
LIMIT 3;