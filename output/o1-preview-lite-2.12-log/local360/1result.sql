WITH session_counts AS (
  SELECT session, COUNT(*) AS event_count
  FROM activity_log
  WHERE search_type IS NOT NULL AND search_type <> ''
    AND path NOT LIKE '%/detail%'
    AND path NOT LIKE '%/complete%'
  GROUP BY session
),
min_event_count AS (
  SELECT MIN(event_count) AS min_count FROM session_counts
),
min_sessions AS (
  SELECT session FROM session_counts WHERE event_count = (SELECT min_count FROM min_event_count)
)
SELECT
  session AS Session,
  GROUP_CONCAT(DISTINCT path) AS Paths,
  GROUP_CONCAT(DISTINCT search_type) AS Search_Types
FROM activity_log
WHERE session IN (SELECT session FROM min_sessions)
  AND search_type IS NOT NULL AND search_type <> ''
  AND path NOT LIKE '%/detail%'
  AND path NOT LIKE '%/complete%'
GROUP BY session;