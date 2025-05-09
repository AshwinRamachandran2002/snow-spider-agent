WITH
-- 1) First time each session reaches a “/detail” click or “/complete” conversion
first_conv AS (
    SELECT
        "session",
        MIN("stamp") AS first_stamp
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    GROUP BY "session"
),

-- 2) Count (possibly 0) of non-empty-search events that happened *before* that time
pre_counts AS (
    SELECT
        f."session",
        COUNT(a."session") AS pre_event_cnt        -- COUNT on LEFT JOIN → 0 when no rows
    FROM first_conv        AS f
    LEFT JOIN "activity_log" AS a
           ON a."session" = f."session"
          AND a."stamp"   < f.first_stamp
          AND a."search_type" <> ''
    GROUP BY f."session"
),

-- 3) The minimum of those counts
min_cnt AS (
    SELECT MIN(pre_event_cnt) AS min_cnt
    FROM pre_counts
),

-- 4) Row that is the very first “/detail” or “/complete” event for every session
first_event AS (
    SELECT l."session",
           l."path",
           l."search_type"
    FROM "activity_log" l
    JOIN first_conv f
      ON l."session" = f."session"
     AND l."stamp"   = f.first_stamp
)

-- 5) Final answer – sessions whose pre-event count equals the minimum
SELECT DISTINCT
       e."session",
       e."path",
       e."search_type"
FROM   pre_counts pc
JOIN   min_cnt     m  ON pc.pre_event_cnt = m.min_cnt
JOIN   first_event e  ON e."session"      = pc."session";