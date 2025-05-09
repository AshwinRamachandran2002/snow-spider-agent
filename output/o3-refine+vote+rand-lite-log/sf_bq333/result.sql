WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS SESSION_DURATION_SECONDS
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "browser", "session_id"
),
browser_stats AS (
    SELECT
        "browser",
        AVG(SESSION_DURATION_SECONDS)  AS AVG_SESSION_DURATION_SECONDS,
        COUNT("session_id")            AS TOTAL_SESSIONS
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT("session_id") > 10
)
SELECT
    "browser",
    ROUND(AVG_SESSION_DURATION_SECONDS, 4) AS AVG_SESSION_DURATION_SECONDS
FROM browser_stats
ORDER BY AVG_SESSION_DURATION_SECONDS ASC, "browser" ASC
LIMIT 3;