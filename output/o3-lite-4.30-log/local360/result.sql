WITH goal AS (
    SELECT
        "session",
        MIN("stamp") AS first_goal_stamp
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    GROUP BY "session"
),
pre_events AS (
    SELECT
        a."session",
        a."stamp",
        a."path",
        a."search_type"
    FROM "activity_log" a
    JOIN goal g ON a."session" = g."session"
    WHERE a."search_type" IS NOT NULL
      AND a."search_type" <> ''
      AND a."stamp" < g.first_goal_stamp
),
cnt AS (
    SELECT "session", COUNT(*) AS cnt_events
    FROM pre_events
    GROUP BY "session"
),
min_cnt AS (
    SELECT MIN(cnt_events) AS min_events FROM cnt
),
target_sessions AS (
    SELECT c."session"
    FROM cnt c
    JOIN min_cnt m ON c.cnt_events = m.min_events
)
SELECT
    p."session" AS session_id,
    p."path",
    p."search_type"
FROM pre_events p
JOIN target_sessions t ON p."session" = t."session"
ORDER BY p."session", p."stamp";