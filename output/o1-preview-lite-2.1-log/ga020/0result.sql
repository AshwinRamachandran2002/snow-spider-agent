SELECT
  quickplay_event_type,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN week = 1 THEN `user_pseudo_id` END), COUNT(DISTINCT CASE WHEN week = 0 THEN `user_pseudo_id` END)) * 100, 4) AS retention_rate_second_week
FROM (
  SELECT
    `user_pseudo_id`,
    `event_name` AS quickplay_event_type,
    DATE_DIFF(DATE(TIMESTAMP_MICROS(`event_timestamp`)), DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`)), WEEK) AS week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE `event_name` LIKE '%_quickplay'
    AND DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`)) BETWEEN DATE('2018-08-01') AND DATE('2018-08-15')
)
WHERE week BETWEEN 0 AND 1
GROUP BY quickplay_event_type
ORDER BY retention_rate_second_week ASC
LIMIT 1;