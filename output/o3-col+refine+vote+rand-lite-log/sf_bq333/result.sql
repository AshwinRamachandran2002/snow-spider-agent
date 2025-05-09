WITH session_durations AS (          -- one row per (browser, session_id)
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000 AS "session_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY "browser", "session_id"
)
SELECT
    "browser",
    AVG("session_seconds") AS "avg_session_seconds"
FROM session_durations
GROUP BY "browser"
HAVING COUNT(*) > 10                  -- only keep browsers with > 10 sessions
ORDER BY "avg_session_seconds" ASC    -- shortest average durations first
LIMIT 3;                              -- three fastest browsers