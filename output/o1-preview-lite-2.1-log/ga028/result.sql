WITH week0_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180708'
    AND DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) BETWEEN '2018-07-02' AND '2018-07-08'
),

week_retention AS (
  SELECT 0 AS WeekNumber, 'Week0' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM week0_users

  UNION ALL

  SELECT 1 AS WeekNumber, 'Week1' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20180715'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM week0_users)

  UNION ALL

  SELECT 2 AS WeekNumber, 'Week2' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180716' AND '20180722'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM week0_users)

  UNION ALL

  SELECT 3 AS WeekNumber, 'Week3' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180723' AND '20180729'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM week0_users)

  UNION ALL

  SELECT 4 AS WeekNumber, 'Week4' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180730' AND '20180805'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM week0_users)
)

SELECT Week, Number_of_Users
FROM week_retention
ORDER BY WeekNumber;