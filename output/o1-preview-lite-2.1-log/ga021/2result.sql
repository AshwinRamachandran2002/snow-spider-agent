WITH session_users AS (
  -- Users who started a session between July 2, 2018, and July 16, 2018
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
),
initial_events AS (
  -- Users' first quickplay events and their types within the specified period
  SELECT
    user_pseudo_id,
    event_name AS quickplay_event_type,
    MIN(event_timestamp) AS first_quickplay_timestamp
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name LIKE '%quickplay'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
  GROUP BY user_pseudo_id, event_name
),
retained_users AS (
  -- Users who had quickplay events two weeks after their initial quickplay event
  SELECT DISTINCT
    i.user_pseudo_id,
    i.quickplay_event_type
  FROM initial_events i
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON i.user_pseudo_id = e.user_pseudo_id
  WHERE e.event_timestamp BETWEEN i.first_quickplay_timestamp + (14 * 86400000000)
                              AND i.first_quickplay_timestamp + (28 * 86400000000)
    AND e.event_name LIKE '%quickplay'
    AND e._TABLE_SUFFIX BETWEEN '20180716' AND '20180813'
)
-- Calculate the retention rate per quickplay event type
SELECT
  i.quickplay_event_type,
  ROUND((COUNT(DISTINCT retained_users.user_pseudo_id) / COUNT(DISTINCT i.user_pseudo_id)) * 100, 4) AS retention_rate_after_two_weeks
FROM initial_events i
LEFT JOIN retained_users
  ON i.user_pseudo_id = retained_users.user_pseudo_id
  AND i.quickplay_event_type = retained_users.quickplay_event_type
GROUP BY i.quickplay_event_type;