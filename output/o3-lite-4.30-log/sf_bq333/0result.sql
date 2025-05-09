WITH session_bounds AS (
    SELECT
        "session_id",
        MIN("created_at") AS session_start,
        MAX("created_at") AS session_end,
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS duration_seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "session_id"
),
session_browser AS (
    SELECT
        e."browser",
        sb.duration_seconds
    FROM session_bounds sb
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS e
      ON e."session_id" = sb."session_id"
     AND e."created_at" = sb.session_start
),
browser_stats AS (
    SELECT
        "browser",
        AVG(duration_seconds) AS avg_session_seconds
    FROM session_browser
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND(avg_session_seconds, 4) AS average_session_duration_seconds
FROM browser_stats
ORDER BY avg_session_seconds
LIMIT 3;