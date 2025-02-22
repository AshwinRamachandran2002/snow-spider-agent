-- Task: For each event in the activity log, determine whether the next path in the same session (ordered by descending timestamp) is '/detail', and add a flag 'has_session_click' accordingly. Display the session, stamp, path, search_type, and 'has_session_click' flag.

SELECT
  "session",
  "stamp",
  "path",
  "search_type",
  CASE
    WHEN LAG("path") OVER (PARTITION BY "session" ORDER BY "stamp" DESC) = '/detail'
      THEN 1
    ELSE 0
  END AS "has_session_click"
FROM
  LOG.LOG.ACTIVITY_LOG;