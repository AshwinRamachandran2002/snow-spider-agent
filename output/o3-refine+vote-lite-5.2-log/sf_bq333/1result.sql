WITH session_durations AS (
    SELECT
        "session_id",
        "browser",
        ( MAX("created_at") - MIN("created_at") ) / 1000000.0 AS session_duration_seconds   -- µs → s
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "session_id", "browser"
),
browser_avg AS (
    SELECT
        "browser",
        AVG(session_duration_seconds) AS avg_session_duration_seconds,
        COUNT("session_id")          AS total_sessions
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT("session_id") > 10            -- only browsers with >10 sessions
)
SELECT
    "browser",
    ROUND(avg_session_duration_seconds, 4) AS avg_session_duration_seconds
FROM browser_avg
ORDER BY avg_session_duration_seconds ASC NULLS LAST, "browser"
LIMIT 3;