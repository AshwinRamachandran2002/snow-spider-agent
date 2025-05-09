WITH session_durations AS (
    SELECT
        "session_id",
        "browser",
        (MAX("created_at") - MIN("created_at")) / 1000000 AS "duration_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY
        "browser",
        "session_id"
),
browser_averages AS (
    SELECT
        "browser",
        AVG("duration_seconds") AS "avg_session_seconds",
        COUNT(*)               AS "num_sessions"
    FROM session_durations
    GROUP BY
        "browser"
    HAVING
        COUNT(*) > 10          -- only keep browsers with more than 10 sessions
)
SELECT
    "browser",
    "avg_session_seconds"
FROM browser_averages
ORDER BY
    "avg_session_seconds" ASC
LIMIT 3;