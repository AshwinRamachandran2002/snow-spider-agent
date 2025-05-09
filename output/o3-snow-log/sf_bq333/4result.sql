WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS duration_seconds   -- micro-seconds → seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "browser", "session_id"
),
browser_avg AS (
    SELECT
        "browser",
        COUNT(*)                                       AS total_sessions,
        AVG(duration_seconds)                          AS avg_session_duration_seconds
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10                              -- only browsers with >10 sessions
)
SELECT
    "browser",
    ROUND(avg_session_duration_seconds, 4) AS avg_session_duration_seconds
FROM browser_avg
ORDER BY avg_session_duration_seconds ASC            -- shortest first
LIMIT 3;