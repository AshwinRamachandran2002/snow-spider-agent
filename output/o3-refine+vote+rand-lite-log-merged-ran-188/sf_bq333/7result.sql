WITH "SESSION_DURATIONS" AS (
    /* duration in seconds for every session */
    SELECT
        "session_id",
        ANY_VALUE("browser") AS "browser",
        MIN("created_at")          AS "min_ts",
        MAX("created_at")          AS "max_ts",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "session_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "session_id"
),
"BROWSER_AVG" AS (
    /* average duration per browser, keep only browsers with >10 sessions */
    SELECT
        "browser",
        AVG("session_seconds") AS "avg_seconds",
        COUNT(*)              AS "session_count"
    FROM "SESSION_DURATIONS"
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND("avg_seconds", 4) AS "average_session_duration_seconds"
FROM "BROWSER_AVG"
ORDER BY "avg_seconds" ASC, "browser"
LIMIT 3;