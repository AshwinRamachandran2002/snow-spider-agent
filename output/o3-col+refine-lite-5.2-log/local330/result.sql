WITH per_session AS (
  -- find first and last timestamp per session
  SELECT
    "session",
    MIN("stamp") AS first_stamp,
    MAX("stamp") AS last_stamp
  FROM "activity_log"
  GROUP BY "session"
),
landing_exit AS (
  -- collect landing and/or exit pages for every session
  SELECT DISTINCT
    a."session",
    a."path"
  FROM "activity_log" AS a
  JOIN per_session AS p
    ON a."session" = p."session"
   AND (a."stamp" = p.first_stamp OR a."stamp" = p.last_stamp)
)
-- count how many unique sessions each page appears in
SELECT
  "path",
  COUNT(DISTINCT "session") AS "unique_sessions"
FROM landing_exit
GROUP BY "path"
ORDER BY "unique_sessions" DESC, "path";