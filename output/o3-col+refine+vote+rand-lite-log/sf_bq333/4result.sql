WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "duration_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "browser", "session_id"
),
browser_avgs AS (
    SELECT
        "browser",
        AVG("duration_seconds") AS "avg_session_seconds"
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND("avg_session_seconds", 4) AS "avg_session_seconds"
FROM browser_avgs
ORDER BY "avg_session_seconds" ASC NULLS LAST
LIMIT 3;