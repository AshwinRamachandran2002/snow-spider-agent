WITH session_durations AS (   -- duration for every individual session
    SELECT
        "browser",
        "session_id",
        ( MAX("created_at") - MIN("created_at") ) / 1000000.0   AS session_duration_seconds   -- micro->seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "browser", "session_id"
),
browser_average AS (         -- average duration & session count per browser
    SELECT
        "browser",
        AVG(session_duration_seconds) AS avg_session_duration_seconds,
        COUNT(*)                     AS total_sessions
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10            -- only browsers with >10 sessions
)
SELECT
    "browser",
    ROUND(avg_session_duration_seconds, 4) AS "avg_session_duration_seconds"
FROM browser_average
ORDER BY avg_session_duration_seconds ASC
LIMIT 3;