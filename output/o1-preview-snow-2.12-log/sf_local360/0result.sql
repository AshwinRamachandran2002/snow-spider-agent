WITH session_counts AS (
  SELECT "session", COUNT(*) AS "event_count"
  FROM LOG.LOG.ACTIVITY_LOG
  WHERE "search_type" IS NOT NULL AND "search_type" != ''
    AND "session" NOT IN (
      SELECT DISTINCT "session"
      FROM LOG.LOG.ACTIVITY_LOG
      WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    )
  GROUP BY "session"
),
min_count AS (
  SELECT MIN("event_count") AS "min_event_count"
  FROM session_counts
),
sessions_with_min_events AS (
  SELECT "session"
  FROM session_counts
  WHERE "event_count" = (SELECT "min_event_count" FROM min_count)
)
SELECT a."session", a."path", a."search_type"
FROM LOG.LOG.ACTIVITY_LOG a
WHERE a."session" IN (SELECT "session" FROM sessions_with_min_events)
  AND a."search_type" IS NOT NULL AND a."search_type" != ''
  AND a."session" NOT IN (
    SELECT DISTINCT "session"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
  )
ORDER BY a."session", a."stamp";