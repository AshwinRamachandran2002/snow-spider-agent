WITH landing AS (
    SELECT al."session",
           (
               SELECT al2."path"
               FROM "activity_log" AS al2
               WHERE al2."session" = al."session"
               ORDER BY datetime(al2."stamp") ASC
               LIMIT 1
           ) AS web_page
    FROM "activity_log" AS al
    GROUP BY al."session"
),
exit_page AS (
    SELECT al."session",
           (
               SELECT al2."path"
               FROM "activity_log" AS al2
               WHERE al2."session" = al."session"
               ORDER BY datetime(al2."stamp") DESC
               LIMIT 1
           ) AS web_page
    FROM "activity_log" AS al
    GROUP BY al."session"
),
combined AS (
    SELECT "session", web_page FROM landing
    UNION
    SELECT "session", web_page FROM exit_page
)
SELECT
    web_page,
    COUNT(DISTINCT "session") AS total_sessions
FROM combined
WHERE web_page IS NOT NULL AND web_page <> ''
GROUP BY web_page
ORDER BY total_sessions DESC, web_page;