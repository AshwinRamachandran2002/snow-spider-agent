WITH session_durations AS (   -- duration (in seconds) for every individual session
    SELECT
        "session_id",
        MIN("browser")                                   AS "browser",  -- browser used in the session
        (MAX("created_at") - MIN("created_at"))/1000000.0 AS "session_duration_sec"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "session_id"
),
browser_stats AS (           -- average duration per browser, keep only browsers with >10 sessions
    SELECT
        "browser",
        AVG("session_duration_sec") AS "avg_session_duration_sec",
        COUNT(*)                    AS "total_sessions"
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    "browser",
    ROUND("avg_session_duration_sec", 4) AS "average_session_duration_seconds"
FROM browser_stats
ORDER BY "avg_session_duration_sec" ASC
LIMIT 3;