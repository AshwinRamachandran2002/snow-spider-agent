WITH "PER_SESSION" AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "session_duration_sec"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY
        "browser",
        "session_id"
),
"AVG_BY_BROWSER" AS (
    SELECT
        "browser",
        AVG("session_duration_sec") AS "avg_session_duration_sec",
        COUNT(*) AS "total_sessions"
    FROM "PER_SESSION"
    GROUP BY
        "browser"
    HAVING
        COUNT(*) > 10          -- only browsers with more than 10 sessions
)
SELECT
    "browser",
    "avg_session_duration_sec"
FROM "AVG_BY_BROWSER"
ORDER BY
    "avg_session_duration_sec" ASC,   -- shortest average duration first
    "browser" ASC
LIMIT 3;