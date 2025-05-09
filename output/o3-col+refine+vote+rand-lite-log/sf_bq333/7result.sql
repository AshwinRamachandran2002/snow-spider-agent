WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000 AS "session_dur_sec"   -- convert µs to seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY
        "browser",
        "session_id"
)

SELECT
    "browser",
    AVG("session_dur_sec") AS "avg_session_duration_sec"
FROM session_durations
GROUP BY "browser"
HAVING COUNT(*) > 10                      -- only keep browsers with more than 10 sessions
ORDER BY "avg_session_duration_sec" ASC   -- shortest average sessions first
LIMIT 3;