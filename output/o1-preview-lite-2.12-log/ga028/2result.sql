WITH events AS (
  SELECT event_timestamp, user_pseudo_id, user_first_touch_timestamp
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
),
new_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM events
  WHERE DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) BETWEEN '2018-07-02' AND '2018-07-08'
),
user_activity AS (
  SELECT DISTINCT user_pseudo_id,
    DATE_TRUNC(DATE(TIMESTAMP_MICROS(event_timestamp)), WEEK(MONDAY)) AS week_start
  FROM events
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2018-07-02' AND '2018-10-02'
),
retention AS (
  SELECT
    DATE_DIFF(week_start, DATE('2018-07-02'), WEEK(MONDAY)) AS week_num,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM user_activity
  GROUP BY week_num
),
total_new_users AS (
  SELECT COUNT(DISTINCT user_pseudo_id) AS total_new_users_value
  FROM new_users
)
SELECT Week, Number_of_users FROM (
  SELECT
    0 AS week_num,
    'Week 0' AS Week,
    total_new_users_value AS Number_of_users
  FROM total_new_users
  UNION ALL
  SELECT
    week_num,
    CONCAT('Week ', CAST(week_num AS STRING)) AS Week,
    retained_users AS Number_of_users
  FROM retention
  WHERE week_num BETWEEN 1 AND 4
)
ORDER BY week_num;