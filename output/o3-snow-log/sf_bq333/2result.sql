WITH "sessions" AS (
    /* duration (in seconds) for every user’s session */
    SELECT
        "browser",
        "user_id",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "session_duration_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    WHERE "user_id" IS NOT NULL
    GROUP BY
        "browser",
        "user_id",
        "session_id"
),
"browser_stats" AS (
    /* average duration per browser, keeping only browsers with >10 sessions */
    SELECT
        "browser",
        AVG("session_duration_seconds") AS "avg_session_duration_seconds",
        COUNT(*) AS "session_count"
    FROM "sessions"
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND("avg_session_duration_seconds", 4) AS "avg_session_duration_seconds"
FROM "browser_stats"
ORDER BY
    "avg_session_duration_seconds" ASC NULLS LAST
LIMIT 3;