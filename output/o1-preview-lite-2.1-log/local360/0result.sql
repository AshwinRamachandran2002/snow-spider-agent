WITH sessions_no_detail_complete AS (
  SELECT "session", COUNT(*) AS event_count
  FROM "activity_log"
  WHERE "search_type" IS NOT NULL AND "search_type" != ''
  GROUP BY "session"
  HAVING SUM(CASE WHEN "option" = 'detail' OR "path" LIKE '%/complete%' THEN 1 ELSE 0 END) = 0
),
sessions_with_min_events AS (
  SELECT "session"
  FROM sessions_no_detail_complete
  WHERE event_count = (
    SELECT MIN(event_count)
    FROM sessions_no_detail_complete
  )
)
SELECT "session" AS Session,
       GROUP_CONCAT("path", ';') AS Paths,
       GROUP_CONCAT(DISTINCT "search_type") AS Search_Types
FROM "activity_log"
WHERE "session" IN (SELECT "session" FROM sessions_with_min_events)
GROUP BY "session";