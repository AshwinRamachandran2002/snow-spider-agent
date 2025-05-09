WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS duration_sec   -- micro‑seconds → seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"
    GROUP BY
        "browser",
        "session_id"
),
browser_averages AS (
    SELECT
        "browser",
        AVG(duration_sec) AS avg_session_duration_sec,
        COUNT(*)           AS total_sessions
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10          -- only keep browsers with more than 10 sessions
)
SELECT
    "browser",
    ROUND(avg_session_duration_sec, 4) AS avg_session_duration_seconds
FROM browser_averages
ORDER BY
    avg_session_duration_sec ASC,     -- shortest first
    "browser" ASC
LIMIT 3;                               -- three browsers with the shortest averages