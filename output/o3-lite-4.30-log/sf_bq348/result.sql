WITH hist_med_nodes AS (
    SELECT DISTINCT
           h."id"        AS node_id,
           h."username"  AS username
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."HISTORY_NODES" h
    WHERE  CAST(h."latitude"  AS FLOAT) BETWEEN 18.4519921 AND 33.6519921
      AND  CAST(h."longitude" AS FLOAT) BETWEEN 31.1798246 AND 54.3798246
      AND  h."all_tags" IS NOT NULL
      AND  h."all_tags"::STRING <> '[]'
      AND  (
              LOWER(h."all_tags"::STRING) LIKE '%hospi%'  OR
              LOWER(h."all_tags"::STRING) LIKE '%clinic%' OR
              LOWER(h."all_tags"::STRING) LIKE '%doctor%'
           )
      AND  NOT EXISTS (
              SELECT 1
              FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_NODES" p
              WHERE p."id" = h."id"
           )
)
SELECT username,
       COUNT(*) AS removed_nodes
FROM   hist_med_nodes
GROUP  BY username
ORDER  BY removed_nodes DESC NULLS LAST, username
LIMIT  3;