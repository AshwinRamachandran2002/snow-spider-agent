WITH session_bounds AS (
    /* Get the first and last timestamp for every session */
    SELECT
        "session",
        MIN(stamp) AS first_stamp,
        MAX(stamp) AS last_stamp
    FROM activity_log
    GROUP BY "session"
),
landing_pages AS (
    /* Page visited at the first timestamp (landing) */
    SELECT
        a."session",
        a.path
    FROM activity_log AS a
    JOIN session_bounds AS b
      ON a."session" = b."session"
     AND a.stamp   = b.first_stamp
),
exit_pages AS (
    /* Page visited at the last timestamp (exit) */
    SELECT
        a."session",
        a.path
    FROM activity_log AS a
    JOIN session_bounds AS b
      ON a."session" = b."session"
     AND a.stamp   = b.last_stamp
),
landing_or_exit AS (
    /* Union ensures each (session, path) pair is counted once,
       even if the same page is both landing and exit */
    SELECT "session", path FROM landing_pages
    UNION
    SELECT "session", path FROM exit_pages
)
SELECT
    path,
    COUNT(DISTINCT "session") AS unique_session_count
FROM landing_or_exit
GROUP BY path
ORDER BY unique_session_count DESC, path;