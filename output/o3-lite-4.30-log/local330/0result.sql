WITH landing AS (
    SELECT a.session,
           a.path
    FROM activity_log a
    JOIN (
        SELECT session, MIN(stamp) AS first_stamp
        FROM activity_log
        GROUP BY session
    ) f
      ON a.session = f.session
     AND a.stamp   = f.first_stamp
    WHERE a.path IS NOT NULL
      AND TRIM(a.path) <> ''
),
exit AS (
    SELECT a.session,
           a.path
    FROM activity_log a
    JOIN (
        SELECT session, MAX(stamp) AS last_stamp
        FROM activity_log
        GROUP BY session
    ) e
      ON a.session = e.session
     AND a.stamp   = e.last_stamp
    WHERE a.path IS NOT NULL
      AND TRIM(a.path) <> ''
),
combined AS (
    SELECT DISTINCT session, path FROM landing
    UNION
    SELECT DISTINCT session, path FROM exit
)
SELECT
    path AS web_page,
    COUNT(DISTINCT session) AS total_sessions
FROM combined
GROUP BY path
ORDER BY total_sessions DESC, web_page;