WITH landing AS (
    SELECT session, path
    FROM (
        SELECT
            session,
            path,
            ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp) AS rn
        FROM activity_log
        WHERE path IS NOT NULL
    )
    WHERE rn = 1
),
exit AS (
    SELECT session, path
    FROM (
        SELECT
            session,
            path,
            ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp DESC) AS rn
        FROM activity_log
        WHERE path IS NOT NULL
    )
    WHERE rn = 1
),
landing_exit_sessions AS (
    /* UNION removes duplicates, so a session counted once per page */
    SELECT session, path FROM landing
    UNION
    SELECT session, path FROM exit
)
SELECT
    path,
    COUNT(DISTINCT session) AS unique_session_count
FROM landing_exit_sessions
GROUP BY path
ORDER BY unique_session_count DESC, path;