WITH session_durations AS (
    -- calculate duration (in seconds) of every individual session
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS duration_seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY
        "browser",
        "session_id"
),
browser_averages AS (
    -- average the session durations per browser
    SELECT
        "browser",
        ROUND(AVG(duration_seconds), 4) AS average_session_duration_seconds,
        COUNT(*) AS total_sessions
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10          -- only keep browsers with > 10 sessions
)
SELECT
    "browser",
    average_session_duration_seconds
FROM browser_averages
ORDER BY
    average_session_duration_seconds ASC
LIMIT 3;           -- three browsers with the shortest average session duration