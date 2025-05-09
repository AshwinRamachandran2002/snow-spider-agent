SELECT COUNT(DISTINCT session) AS Number_of_sessions
FROM (
  SELECT session,
    MIN(CASE WHEN path = '/input' THEN stamp END) AS input_time,
    MIN(CASE WHEN path = '/confirm' THEN stamp END) AS confirm_time
  FROM activity_log
  GROUP BY session
) t
WHERE input_time IS NOT NULL AND confirm_time IS NOT NULL
  AND input_time < confirm_time;