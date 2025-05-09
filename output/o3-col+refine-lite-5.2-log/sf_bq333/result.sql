WITH sessions AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000 AS session_dur_secs          -- microseconds → seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "browser", "session_id"
),
browser_avg AS (
    SELECT
        "browser",
        AVG(session_dur_secs) AS avg_session_dur_secs,
        COUNT(*)              AS total_sessions
    FROM sessions
    GROUP BY "browser"
    HAVING COUNT(*) > 10                                       -- only browsers with >10 sessions
)
SELECT
    "browser",
    avg_session_dur_secs
FROM browser_avg
ORDER BY avg_session_dur_secs ASC
LIMIT 3;                                                       -- three shortest averages