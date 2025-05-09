WITH new_users AS (
  SELECT DISTINCT user_pseudo_id, user_first_touch_timestamp
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) BETWEEN '2018-09-01' AND '2018-09-30'
),
uninstalls_within_7_days AS (
  SELECT 
    nu.user_pseudo_id,
    TIMESTAMP_MICROS(nu.user_first_touch_timestamp) AS first_open_time,
    MIN(TIMESTAMP_MICROS(e.event_timestamp)) AS uninstall_time
  FROM new_users nu
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = nu.user_pseudo_id
  WHERE e.event_name = 'app_remove'
  GROUP BY nu.user_pseudo_id, first_open_time
  HAVING DATE_DIFF(DATE(uninstall_time), DATE(first_open_time), DAY) <= 7
),
crashes_before_uninstall AS (
  SELECT DISTINCT u.user_pseudo_id
  FROM uninstalls_within_7_days u
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = u.user_pseudo_id
  WHERE e.event_name = 'app_exception'
    AND TIMESTAMP_MICROS(e.event_timestamp) <= u.uninstall_time
)
SELECT
  ROUND(
    (SELECT COUNT(*) FROM crashes_before_uninstall) * 100.0 / (SELECT COUNT(*) FROM uninstalls_within_7_days),
    4
  ) AS Percentage