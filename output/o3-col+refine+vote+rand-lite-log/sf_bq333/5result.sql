WITH session_durations AS (   -- duration (sec) for every individual session
    SELECT
        "session_id",
        "browser",
        (MAX("created_at") - MIN("created_at")) / 1000000 AS duration_seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "session_id", "browser"
),
browser_avgs AS (            -- average duration per browser, keep browsers with > 10 sessions
    SELECT
        "browser"                               AS browser,
        COUNT(*)                                AS num_sessions,
        ROUND(AVG(duration_seconds), 4)         AS avg_session_duration_seconds
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    browser,
    avg_session_duration_seconds
FROM browser_avgs
ORDER BY avg_session_duration_seconds ASC
LIMIT 3;