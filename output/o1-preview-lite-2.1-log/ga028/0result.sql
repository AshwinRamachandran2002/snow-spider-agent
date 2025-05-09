WITH new_users AS (
  SELECT user_pseudo_id
  FROM (
    SELECT user_pseudo_id, MIN(event_date) AS first_session_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'session_start'
    GROUP BY user_pseudo_id
  )
  WHERE first_session_date BETWEEN '20180702' AND '20180708'
),
retention AS (
  SELECT 'Week0' AS Week, COUNT(*) AS Number_of_Users FROM new_users
  UNION ALL
  SELECT 'Week1' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND event_date BETWEEN '20180709' AND '20180715'
  UNION ALL
  SELECT 'Week2' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND event_date BETWEEN '20180716' AND '20180722'
  UNION ALL
  SELECT 'Week3' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND event_date BETWEEN '20180723' AND '20180729'
  UNION ALL
  SELECT 'Week4' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_Users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND event_date BETWEEN '20180730' AND '20180805'
)
SELECT Week, Number_of_Users
FROM retention
ORDER BY Week;