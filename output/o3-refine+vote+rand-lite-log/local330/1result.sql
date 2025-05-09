WITH ranked AS (
    SELECT
        session,
        path,
        stamp,
        ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp, rowid)  AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp DESC, rowid DESC) AS rn_last
    FROM activity_log
),
landing AS (
    SELECT session, path
    FROM ranked
    WHERE rn_first = 1
),
exit AS (
    SELECT session, path
    FROM ranked
    WHERE rn_last = 1
),
combined AS (
    -- union keeps one record per (session, path) even if the page is both landing and exit
    SELECT session, path FROM landing
    UNION
    SELECT session, path FROM exit
)
SELECT
    path,
    COUNT(DISTINCT session) AS unique_session_count
FROM combined
GROUP BY path
ORDER BY unique_session_count DESC, path;