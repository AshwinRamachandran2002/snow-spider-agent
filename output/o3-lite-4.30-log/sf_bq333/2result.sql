WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1e6 AS session_seconds   -- μs → s
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    WHERE "browser" IS NOT NULL
    GROUP BY "browser", "session_id"
),
average_by_browser AS (
    SELECT
        "browser",
        AVG(session_seconds) AS average_session_duration_seconds,
        COUNT(*)             AS total_sessions
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND(average_session_duration_seconds, 4) AS average_session_duration_seconds
FROM average_by_browser
ORDER BY average_session_duration_seconds ASC
LIMIT 3;