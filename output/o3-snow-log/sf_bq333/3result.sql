WITH sessions AS (
    SELECT
        "browser",
        "session_id",
        /* duration per session in seconds */
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "session_duration_seconds"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY
        "browser",
        "session_id"
),
browser_stats AS (
    SELECT
        "browser",
        AVG("session_duration_seconds") AS "avg_session_duration_seconds",
        COUNT(*) AS "total_sessions"
    FROM
        sessions
    GROUP BY
        "browser"
    HAVING
        COUNT(*) > 10          -- only browsers with more than 10 sessions
)
SELECT
    "browser",
    ROUND("avg_session_duration_seconds", 4) AS "avg_session_duration_seconds"
FROM
    browser_stats
ORDER BY
    "avg_session_duration_seconds" ASC NULLS LAST
LIMIT 3;