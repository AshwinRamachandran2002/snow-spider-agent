WITH
-- 1) first event in each session that is a “/detail” click or “/complete” conversion
first_click AS (
    SELECT
        "session",
        MIN("stamp") AS first_click_stamp
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    GROUP BY "session"
),

-- 2) events that occur before that first click / conversion
pre_events AS (
    SELECT
        al."session",
        al."path",
        al."search_type"
    FROM "activity_log" al
    JOIN first_click fc
      ON al."session" = fc."session"
    WHERE al."stamp" < fc.first_click_stamp
      AND al."search_type" IS NOT NULL
      AND al."search_type" <> ''
),

-- 3) count of such events for every session
pre_counts AS (
    SELECT
        fc."session",
        COUNT(pe."path") AS num_pre
    FROM first_click fc
    LEFT JOIN pre_events pe
      ON fc."session" = pe."session"
    GROUP BY fc."session"
),

-- 4) smallest count across all sessions
min_pre AS (
    SELECT MIN(num_pre) AS min_num_pre
    FROM pre_counts
)

-- 5) return sessions whose count equals that minimum,
--    along with each qualifying (counted) event’s path and search_type
SELECT
    pc."session",
    pe."path",
    pe."search_type"
FROM pre_counts pc
JOIN min_pre mp
  ON pc.num_pre = mp.min_num_pre
LEFT JOIN pre_events pe
  ON pc."session" = pe."session"
ORDER BY pc."session", pe."path";