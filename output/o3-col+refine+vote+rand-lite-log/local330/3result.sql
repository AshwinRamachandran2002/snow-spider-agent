WITH first_last AS (
  -- Find the first and last timestamp for every session
  SELECT
    "session",
    MIN("stamp") AS "first_stamp",
    MAX("stamp") AS "last_stamp"
  FROM "activity_log"
  GROUP BY "session"
),
boundary_pages AS (
  -- Pick rows whose timestamps match either the landing (first) or exit (last)
  SELECT
    a."session",
    a."path"
  FROM "activity_log" AS a
  JOIN first_last AS fl
    ON  a."session" = fl."session"
   AND a."stamp"   IN (fl."first_stamp", fl."last_stamp")
)
-- Count each session only once per page
SELECT
  "path",
  COUNT(DISTINCT "session") AS "total_unique_sessions"
FROM boundary_pages
GROUP BY "path"
ORDER BY "total_unique_sessions" DESC, "path";