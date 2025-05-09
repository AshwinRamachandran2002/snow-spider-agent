WITH session_durations AS (
    /* 1.  Calculate the length (in seconds) of every session for each browser */
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS duration_seconds   -- micro- to seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY
        "browser",
        "session_id"
),

browser_averages AS (
    /* 2.  Compute average session length and session count per browser */
    SELECT
        "browser",
        AVG(duration_seconds)          AS avg_session_duration,
        COUNT("session_id")            AS total_sessions
    FROM session_durations
    GROUP BY
        "browser"
    HAVING
        COUNT("session_id") > 10       -- keep browsers with more than 10 sessions
)

/* 3.  Return the three browsers with the shortest average session duration */
SELECT
    "browser",
    ROUND(avg_session_duration, 4) AS avg_session_duration_seconds
FROM browser_averages
ORDER BY
    avg_session_duration ASC
LIMIT 3;