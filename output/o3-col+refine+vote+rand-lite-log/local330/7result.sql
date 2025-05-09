WITH landing AS (
    /* first (landing) page in each session */
    SELECT 
        a."session",
        (SELECT a2."path"
         FROM "activity_log" AS a2
         WHERE a2."session" = a."session"
         ORDER BY a2."stamp" ASC
         LIMIT 1) AS "page_path"
    FROM "activity_log" AS a
    GROUP BY a."session"
),
exit AS (
    /* last (exit) page in each session */
    SELECT 
        a."session",
        (SELECT a3."path"
         FROM "activity_log" AS a3
         WHERE a3."session" = a."session"
         ORDER BY a3."stamp" DESC
         LIMIT 1) AS "page_path"
    FROM "activity_log" AS a
    GROUP BY a."session"
),
union_paths AS (
    /* combine landing & exit pages, one row per (session, page) */
    SELECT DISTINCT "session", "page_path" FROM landing
    UNION
    SELECT DISTINCT "session", "page_path" FROM exit
)
SELECT
    "page_path",
    COUNT(DISTINCT "session") AS "unique_sessions"
FROM union_paths
GROUP BY "page_path"
ORDER BY "unique_sessions" DESC,
         "page_path";