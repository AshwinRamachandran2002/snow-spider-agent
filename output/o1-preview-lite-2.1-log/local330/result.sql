WITH all_logs AS (
    SELECT "session", "path" AS "page", "stamp" FROM "activity_log"
    UNION ALL
    SELECT "session", "url" AS "page", "stamp" FROM "read_log"
),
start_pages AS (
    SELECT al."session", al."page"
    FROM all_logs al
    JOIN (
        SELECT "session", MIN("stamp") AS min_stamp
        FROM all_logs
        GROUP BY "session"
    ) ms ON al."session" = ms."session" AND al."stamp" = ms.min_stamp
),
end_pages AS (
    SELECT al."session", al."page"
    FROM all_logs al
    JOIN (
        SELECT "session", MAX("stamp") AS max_stamp
        FROM all_logs
        GROUP BY "session"
    ) ms ON al."session" = ms."session" AND al."stamp" = ms.max_stamp
),
start_end_pages AS (
    SELECT * FROM start_pages
    UNION ALL
    SELECT * FROM end_pages
)
SELECT "page", COUNT(DISTINCT "session") AS "SessionCount"
FROM start_end_pages
GROUP BY "page"
ORDER BY "SessionCount" DESC
LIMIT 100;