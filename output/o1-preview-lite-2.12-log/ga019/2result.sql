SELECT
  ((COUNT(DISTINCT installs.`user_pseudo_id`) - COUNT(DISTINCT uninstalls.`user_pseudo_id`)) * 100.0 / COUNT(DISTINCT installs.`user_pseudo_id`)) AS Percentage_of_users
FROM (
  SELECT DISTINCT `user_pseudo_id`, TIMESTAMP_MICROS(`user_first_touch_timestamp`) AS install_time
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE
    DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`)) BETWEEN '2018-08-01' AND '2018-09-30'
    AND `_TABLE_SUFFIX` BETWEEN '20180801' AND '20180930'
) AS installs
LEFT JOIN (
  SELECT DISTINCT e.`user_pseudo_id`
  FROM (
    SELECT DISTINCT `user_pseudo_id`, TIMESTAMP_MICROS(`user_first_touch_timestamp`) AS install_time
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE
      DATE(TIMESTAMP_MICROS(`user_first_touch_timestamp`)) BETWEEN '2018-08-01' AND '2018-09-30'
      AND `_TABLE_SUFFIX` BETWEEN '20180801' AND '20180930'
  ) AS i
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON i.`user_pseudo_id` = e.`user_pseudo_id`
    AND e.`event_name` = 'app_remove'
    AND `_TABLE_SUFFIX` BETWEEN '20180801' AND '20181007'
    AND TIMESTAMP_MICROS(e.`event_timestamp`) <= i.install_time + INTERVAL 7 DAY
) AS uninstalls
  ON installs.`user_pseudo_id` = uninstalls.`user_pseudo_id`;