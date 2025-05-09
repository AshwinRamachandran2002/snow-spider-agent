WITH new_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) >= DATE '2018-07-02'
    AND DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) < DATE '2018-07-09'
),

user_events AS (
  SELECT DISTINCT user_pseudo_id,
    FLOOR(DATE_DIFF(
      DATE(TIMESTAMP_MICROS(event_timestamp)),
      DATE '2018-07-02',
      WEEK(MONDAY)
    )) AS Week_num
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE
    user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND DATE(TIMESTAMP_MICROS(event_timestamp)) >= DATE '2018-07-02'
    AND DATE(TIMESTAMP_MICROS(event_timestamp)) <= DATE '2018-10-02'
)

SELECT Week, Number_of_users
FROM (
  SELECT 'Week 0' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_users, 0 AS Week_num
  FROM new_users
  UNION ALL
  SELECT
    CONCAT('Week ', CAST(Week_num AS STRING)) AS Week,
    COUNT(DISTINCT user_pseudo_id) AS Number_of_users,
    Week_num
  FROM user_events
  WHERE Week_num BETWEEN 1 AND 4
  GROUP BY Week_num
)
ORDER BY Week_num;