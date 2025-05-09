WITH "SESSION_DURATIONS" AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "session_duration_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    WHERE "session_id" IS NOT NULL
    GROUP BY "browser", "session_id"
),
"BROWSER_AVG" AS (
    SELECT
        "browser",
        AVG("session_duration_seconds") AS "avg_session_duration_seconds",
        COUNT(*) AS "total_sessions"
    FROM "SESSION_DURATIONS"
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND("avg_session_duration_seconds", 4) AS "avg_session_duration_seconds"
FROM "BROWSER_AVG"
ORDER BY "avg_session_duration_seconds" ASC, "browser"
LIMIT 3;