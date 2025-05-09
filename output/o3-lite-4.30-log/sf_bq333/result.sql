WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1e6 AS "session_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    WHERE "browser" IS NOT NULL
      AND "session_id" IS NOT NULL
    GROUP BY "browser", "session_id"
),
avg_durations AS (
    SELECT
        "browser",
        COUNT(*)                       AS "total_sessions",
        AVG("session_seconds")         AS "avg_session_duration_seconds"
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND("avg_session_duration_seconds", 4) AS "average_session_duration_seconds"
FROM avg_durations
ORDER BY "avg_session_duration_seconds" ASC, "browser"
LIMIT 3;