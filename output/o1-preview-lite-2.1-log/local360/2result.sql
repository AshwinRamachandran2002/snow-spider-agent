WITH EventCounts AS (
  SELECT "session", COUNT(*) AS "event_count"
  FROM "activity_log"
  WHERE "search_type" IS NOT NULL AND "search_type" != ''
    AND "session" NOT IN (
      SELECT DISTINCT "session"
      FROM "activity_log"
      WHERE "path" LIKE '%/detail%' OR "path" LIKE '%/complete%'
    )
  GROUP BY "session"
),
MinEventCount AS (
  SELECT MIN("event_count") AS "min_event_count"
  FROM EventCounts
),
TargetSessions AS (
  SELECT "session"
  FROM EventCounts
  WHERE "event_count" = (SELECT "min_event_count" FROM MinEventCount)
)
SELECT
  "session" AS "Session",
  GROUP_CONCAT("path", ';') AS "Paths",
  GROUP_CONCAT("search_type", ';') AS "Search_Types"
FROM (
  SELECT DISTINCT "session", "path", "search_type"
  FROM "activity_log"
  WHERE "session" IN (SELECT "session" FROM TargetSessions)
) AS sub
GROUP BY "session";