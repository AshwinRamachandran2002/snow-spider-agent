WITH session_bounds AS (        -- first & last timestamp of every session
    SELECT
        "session",
        MIN("stamp") AS "first_stamp",
        MAX("stamp") AS "last_stamp"
    FROM "activity_log"
    GROUP BY "session"
),
landing_exit AS (               -- landing-page rows  UNION  exit-page rows
    /* landing pages */
    SELECT sb."session", al."path"
    FROM session_bounds AS sb
    JOIN "activity_log" AS al
      ON al."session" = sb."session"
     AND al."stamp"   = sb."first_stamp"

    UNION                      -- UNION removes (session,path) duplicates
    /* exit pages */
    SELECT sb."session", al."path"
    FROM session_bounds AS sb
    JOIN "activity_log" AS al
      ON al."session" = sb."session"
     AND al."stamp"   = sb."last_stamp"
)
SELECT
    "path"   AS "page",
    COUNT(DISTINCT "session") AS "unique_sessions"   -- count sessions once per page
FROM landing_exit
GROUP BY "path"
ORDER BY "unique_sessions" DESC,
         "page" ASC;