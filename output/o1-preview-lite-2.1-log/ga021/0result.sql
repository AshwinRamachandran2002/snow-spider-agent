WITH session_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
),
initial_events AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_quickplay_timestamp,
    ARRAY_AGG(event_name ORDER BY event_timestamp ASC LIMIT 1)[OFFSET(0)] AS quickplay_event_type
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
    AND event_name LIKE '%_quickplay'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
  GROUP BY user_pseudo_id
),
retention AS (
  SELECT
    initial_events.user_pseudo_id,
    initial_events.quickplay_event_type,
    CASE WHEN COUNT(subsequent_events.event_timestamp) > 0 THEN 1 ELSE 0 END AS retained
  FROM initial_events
  LEFT JOIN `firebase-public-project.analytics_153293282.events_*` AS subsequent_events
    ON subsequent_events.user_pseudo_id = initial_events.user_pseudo_id
    AND subsequent_events.event_timestamp BETWEEN initial_events.first_quickplay_timestamp + 1209600000000
                                               AND initial_events.first_quickplay_timestamp + 1814400000000
  GROUP BY initial_events.user_pseudo_id, initial_events.quickplay_event_type
)
SELECT
  quickplay_event_type,
  ROUND(SUM(retained) * 100.0 / COUNT(*), 4) AS retention_rate_after_two_weeks
FROM retention
GROUP BY quickplay_event_type
ORDER BY retention_rate_after_two_weeks DESC