SELECT "normalized_path" AS "Third_Page", COUNT(*) AS "Count"
FROM (
    SELECT "session", 
           REGEXP_REPLACE("path", '/$', '') AS "normalized_path",
           LAG(REGEXP_REPLACE("path", '/$', '')) OVER (PARTITION BY "session" ORDER BY "stamp") AS "previous_normalized_path_1",
           LAG(REGEXP_REPLACE("path", '/$', ''), 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS "previous_normalized_path_2"
    FROM "LOG"."LOG"."ACTIVITY_LOG"
) sub
WHERE "previous_normalized_path_2" = '/detail' AND "previous_normalized_path_1" = '/detail'
  AND "normalized_path" <> ''
GROUP BY "normalized_path"
ORDER BY "Count" DESC NULLS LAST
LIMIT 3;