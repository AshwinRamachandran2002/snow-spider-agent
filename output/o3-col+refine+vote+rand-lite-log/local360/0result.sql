WITH first_conv AS (          -- ①  first “/detail” or “/complete” time per session
    SELECT
        "session",
        MIN("stamp") AS "first_conv_time"
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%' 
       OR "path" LIKE '%/complete%'
    GROUP BY "session"
),
pre_events AS (               -- ②  count of pre-conversion events that have search_type
    SELECT
        a."session",
        COUNT(*) AS "pre_cnt"
    FROM "activity_log" AS a
    JOIN first_conv  AS f
      ON a."session" = f."session"
    WHERE a."search_type" IS NOT NULL
      AND a."search_type" <> ''
      AND a."stamp" < f."first_conv_time"
    GROUP BY a."session"
),
min_cnt AS (                  -- ③  minimum of those counts
    SELECT MIN("pre_cnt") AS "min_pre_cnt"
    FROM pre_events
)
-- ④  list the actual pre-conversion events for the session(s) whose count equals that minimum
SELECT
    a."session",
    a."path",
    a."search_type"
FROM "activity_log" AS a
JOIN first_conv  AS f   ON a."session" = f."session"
JOIN pre_events  AS p   ON a."session" = p."session"
JOIN min_cnt     AS m   ON p."pre_cnt" = m."min_pre_cnt"
WHERE a."search_type" IS NOT NULL
  AND a."search_type" <> ''
  AND a."stamp" < f."first_conv_time"
ORDER BY a."session",
         a."stamp";