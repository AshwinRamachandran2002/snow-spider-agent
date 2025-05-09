WITH first_click AS (
  /* 1. First “/detail” or “/complete” time-stamp per session */
  SELECT
    "session",
    MIN("stamp") AS "first_click_time"
  FROM "activity_log"
  WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
  GROUP BY "session"
),
pre_event_counts AS (
  /* 2. How many non-empty-search_type events occur before that time? */
  SELECT
    a."session",
    COUNT(*) AS "pre_cnt"
  FROM "activity_log" AS a
  LEFT JOIN first_click AS f
    ON a."session" = f."session"
  WHERE a."search_type" <> ''
    AND (f."first_click_time" IS NULL OR a."stamp" < f."first_click_time")
  GROUP BY a."session"
),
min_cnt AS (
  /* 3. Minimum of those counts */
  SELECT MIN("pre_cnt") AS "min_pre_cnt"
  FROM pre_event_counts
)
 /* 4. Rows that were actually counted for the sessions
       with that minimum pre-event count */
SELECT
  a."session",
  a."path",
  a."search_type"
FROM "activity_log"      AS a
JOIN pre_event_counts    AS p  ON a."session" = p."session"
JOIN min_cnt             AS m  ON p."pre_cnt" = m."min_pre_cnt"
LEFT JOIN first_click    AS f  ON a."session" = f."session"
WHERE a."search_type" <> ''
  AND (f."first_click_time" IS NULL OR a."stamp" < f."first_click_time")
ORDER BY a."session", a."stamp";