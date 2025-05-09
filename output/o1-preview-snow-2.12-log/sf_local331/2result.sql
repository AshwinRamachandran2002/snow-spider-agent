SELECT sub."path" AS "Third_Page", COUNT(*) AS "Count"
FROM (
    SELECT "session", "stamp", "path",
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev_path",
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev_prev_path"
    FROM "LOG"."LOG"."ACTIVITY_LOG"
) sub
WHERE sub."prev_prev_path" IN ('/detail', '/detail/')
  AND sub."prev_path" IN ('/detail', '/detail/')
  AND sub."path" NOT IN ('/detail', '/detail/')
  AND sub."path" IS NOT NULL
GROUP BY sub."path"
ORDER BY "Count" DESC NULLS LAST
LIMIT 3;