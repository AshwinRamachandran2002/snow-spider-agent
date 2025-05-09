WITH first_cv AS (
    SELECT
        "session",
        MIN("stamp") AS cv_time
    FROM "activity_log"
    WHERE "path" IN ('/detail', '/detail/', '/complete', '/complete/')
    GROUP BY "session"
),
pre_events AS (
    SELECT
        a."session",
        a."path",
        a."search_type",
        a."stamp"
    FROM "activity_log" a
    JOIN first_cv f
      ON f."session" = a."session"
    WHERE a."search_type" IS NOT NULL
      AND a."search_type" <> ''
      AND a."stamp" < f.cv_time
),
event_cnt AS (
    SELECT
        "session",
        COUNT(*) AS cnt
    FROM pre_events
    GROUP BY "session"
),
min_cnt AS (
    SELECT MIN(cnt) AS min_value FROM event_cnt
)
SELECT
    p."session"  AS session_id,
    p."path",
    p."search_type"
FROM pre_events p
JOIN event_cnt c ON c."session" = p."session"
JOIN min_cnt  m ON m.min_value  = c.cnt
ORDER BY p."session", p."stamp";