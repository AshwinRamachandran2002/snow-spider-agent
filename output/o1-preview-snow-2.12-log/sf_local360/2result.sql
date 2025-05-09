WITH sessions_without_detail AS (
  SELECT "session", COUNT(*) AS event_count
  FROM LOG.LOG.ACTIVITY_LOG
  WHERE "search_type" IS NOT NULL AND "search_type" != ''
    AND "path" NOT LIKE '%/detail%' AND "path" NOT LIKE '%/complete%'
  GROUP BY "session"
),
min_event_count AS (
  SELECT MIN(event_count) AS min_event_count
  FROM sessions_without_detail
),
min_sessions AS (
  SELECT "session"
  FROM sessions_without_detail
  WHERE event_count = (SELECT min_event_count FROM min_event_count)
)
SELECT a."session", a."path", a."search_type"
FROM LOG.LOG.ACTIVITY_LOG AS a
JOIN min_sessions AS b ON a."session" = b."session"
WHERE a."search_type" IS NOT NULL AND a."search_type" != ''
  AND a."path" NOT LIKE '%/detail%' AND a."path" NOT LIKE '%/complete%'
ORDER BY a."session", a."path";