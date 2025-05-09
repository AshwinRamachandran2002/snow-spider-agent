WITH session_durations AS (
    /* duration (in seconds) of every individual session */
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "session_duration_seconds"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"
    GROUP BY "browser", "session_id"
),
browser_stats AS (
    /* average duration and total session count per browser */
    SELECT
        "browser",
        ROUND(AVG("session_duration_seconds"), 4) AS "avg_session_duration_seconds",
        COUNT(*)                                    AS "total_sessions"
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10          -- keep only browsers with > 10 sessions
)
SELECT
    "browser",
    "avg_session_duration_seconds"
FROM browser_stats
ORDER BY "avg_session_duration_seconds" ASC   -- shortest averages first
LIMIT 3;                                       -- three browsers with shortest averages