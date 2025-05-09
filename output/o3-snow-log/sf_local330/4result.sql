/* 1) For every session, identify the first and last time-stamp  */
WITH stamps AS (
    SELECT
        "session",
        MIN("stamp") AS "first_stamp",
        MAX("stamp") AS "last_stamp"
    FROM LOG.LOG.ACTIVITY_LOG
    GROUP BY "session"
),

/* 2) Pick the page(s) that are either the landing page
       (first_stamp) or the exit page (last_stamp) for the session.
       DISTINCT is used so a session-page pair is counted once
       even if the page is both landing and exit. */
landing_exit_pages AS (
    SELECT DISTINCT
        a."session",
        a."path"
    FROM LOG.LOG.ACTIVITY_LOG AS a
    JOIN stamps              AS s
      ON a."session" = s."session"
     AND (a."stamp" = s."first_stamp"
          OR a."stamp" = s."last_stamp")
)

/* 3) Count how many unique sessions each page appears in
       as landing and/or exit. */
SELECT
    "path",
    COUNT(DISTINCT "session") AS "unique_sessions"
FROM landing_exit_pages
GROUP BY "path"
ORDER BY "unique_sessions" DESC NULLS LAST,   -- most frequent first
         "path";