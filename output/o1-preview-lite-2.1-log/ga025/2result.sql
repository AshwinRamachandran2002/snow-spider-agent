WITH first_open_users AS (
  SELECT DISTINCT user_pseudo_id, MIN(user_first_touch_timestamp) AS first_touch_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
    AND DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) BETWEEN '2018-09-01' AND '2018-09-30'
  GROUP BY user_pseudo_id
),
uninstall_events AS (
  SELECT user_pseudo_id, MIN(event_timestamp) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),
users_uninstalled_within_7days AS (
  SELECT u.user_pseudo_id, u.first_touch_ts, ue.uninstall_ts
  FROM first_open_users u
  JOIN uninstall_events ue ON u.user_pseudo_id = ue.user_pseudo_id
  WHERE TIMESTAMP_MICROS(ue.uninstall_ts) <= TIMESTAMP_MICROS(u.first_touch_ts) + INTERVAL 7 DAY
),
users_with_crash AS (
  SELECT DISTINCT e.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN users_uninstalled_within_7days u ON e.user_pseudo_id = u.user_pseudo_id
  WHERE e.event_name = 'app_exception'
    AND TIMESTAMP_MICROS(e.event_timestamp) BETWEEN TIMESTAMP_MICROS(u.first_touch_ts) AND
        LEAST(TIMESTAMP_MICROS(u.uninstall_ts), TIMESTAMP_MICROS(u.first_touch_ts) + INTERVAL 7 DAY)
)

SELECT
  ROUND((COUNT(DISTINCT users_with_crash.user_pseudo_id) / COUNT(DISTINCT users_uninstalled_within_7days.user_pseudo_id)) * 100, 4) AS Percentage_of_users_who_experienced_app_crash
FROM
  users_uninstalled_within_7days
LEFT JOIN
  users_with_crash
ON users_uninstalled_within_7days.user_pseudo_id = users_with_crash.user_pseudo_id