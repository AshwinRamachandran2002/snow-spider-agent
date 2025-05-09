WITH init AS (
  -- Users’ first quick-play action between 1–15 Aug 2018
  SELECT
    event_name AS quickplay_event,
    user_pseudo_id,
    MIN(event_timestamp) AS first_quickplay_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY quickplay_event, user_pseudo_id
),
retained AS (
  -- Those same users firing session_start 8-14 days later
  SELECT DISTINCT
    i.quickplay_event,
    i.user_pseudo_id
  FROM init AS i
  JOIN `firebase-public-project.analytics_153293282.events_*` AS s
    ON s.user_pseudo_id = i.user_pseudo_id
  WHERE s.event_name = 'session_start'
    AND s.event_timestamp BETWEEN i.first_quickplay_ts + 8*86400000000
                              AND i.first_quickplay_ts + 14*86400000000
    AND _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'      -- need data through +14 d
),
init_cnt AS (
  SELECT quickplay_event, COUNT(DISTINCT user_pseudo_id) AS initial_users
  FROM init
  GROUP BY quickplay_event
),
ret_cnt AS (
  SELECT quickplay_event, COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM retained
  GROUP BY quickplay_event
)
SELECT
  i.quickplay_event,
  initial_users,
  COALESCE(retained_users, 0) AS retained_users,
  SAFE_DIVIDE(retained_users, initial_users) AS week2_retention_rate
FROM init_cnt AS i
LEFT JOIN ret_cnt AS r
ON i.quickplay_event = r.quickplay_event
ORDER BY week2_retention_rate ASC
LIMIT 1;