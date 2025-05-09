WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS session_duration_seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY
        "browser",
        "session_id"
),
browser_averages AS (
    SELECT
        "browser",
        AVG(session_duration_seconds) AS avg_session_duration_seconds,
        COUNT("session_id")          AS total_sessions
    FROM session_durations
    GROUP BY
        "browser"
    HAVING
        COUNT("session_id") > 10
)
SELECT
    "browser",
    ROUND(avg_session_duration_seconds, 4) AS "avg_session_duration_seconds"
FROM browser_averages
ORDER BY
    avg_session_duration_seconds ASC NULLS LAST,
    "browser"
LIMIT 3;