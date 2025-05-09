WITH session_durations AS (
    /* duration (in seconds) of every individual session_id */
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS session_seconds   -- micro‑>seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "browser", "session_id"
),
browser_averages AS (
    /* average duration per browser, keeping only those with >10 sessions */
    SELECT
        "browser",
        AVG(session_seconds) AS avg_session_seconds,
        COUNT(*)             AS total_sessions
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND(avg_session_seconds, 4) AS avg_session_duration_seconds
FROM browser_averages
ORDER BY avg_session_seconds ASC
LIMIT 3;