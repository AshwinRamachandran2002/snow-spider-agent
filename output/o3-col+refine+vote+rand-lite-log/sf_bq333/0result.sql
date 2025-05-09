WITH session_durations AS (
    SELECT
        "browser",
        "session_id",
        (MAX("created_at") - MIN("created_at")) / 1000000.0 AS "duration_seconds"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "browser", "session_id"
),
browser_filter AS (
    SELECT "browser"
    FROM session_durations
    GROUP BY "browser"
    HAVING COUNT(*) > 10
)
SELECT
    sd."browser",
    ROUND(AVG(sd."duration_seconds"), 4) AS "avg_session_seconds"
FROM session_durations sd
JOIN browser_filter bf
  ON sd."browser" = bf."browser"
GROUP BY sd."browser"
ORDER BY "avg_session_seconds" ASC
LIMIT 3;