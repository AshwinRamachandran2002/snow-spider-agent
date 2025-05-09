WITH new_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180708'
    AND user_first_touch_timestamp >= UNIX_MICROS(TIMESTAMP('2018-07-02'))
    AND user_first_touch_timestamp < UNIX_MICROS(TIMESTAMP('2018-07-09'))
)

SELECT 'Week 0' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_users
FROM new_users

UNION ALL

SELECT 'Week 1' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20180715'
  AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)

UNION ALL

SELECT 'Week 2' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180716' AND '20180722'
  AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)

UNION ALL

SELECT 'Week 3' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180723' AND '20180729'
  AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)

UNION ALL

SELECT 'Week 4' AS Week, COUNT(DISTINCT user_pseudo_id) AS Number_of_users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180730' AND '20180805'
  AND user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)

ORDER BY Week;