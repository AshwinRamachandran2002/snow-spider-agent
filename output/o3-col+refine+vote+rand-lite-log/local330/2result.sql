WITH first_last AS (
    /* first & last timestamp per session */
    SELECT
        "session",
        MIN("stamp") AS "first_stamp",
        MAX("stamp") AS "last_stamp"
    FROM "activity_log"
    GROUP BY "session"
),
landing_exit AS (
    /* rows that are landing or exit for the session */
    SELECT
        a."session",
        a."path"
    FROM "activity_log" AS a
    JOIN first_last AS f
      ON a."session" = f."session"
     AND (a."stamp" = f."first_stamp"
          OR a."stamp" = f."last_stamp")
)
SELECT
    "path" AS "page",
    COUNT(DISTINCT "session") AS "total_sessions"
FROM landing_exit
GROUP BY "path"
ORDER BY "total_sessions" DESC;