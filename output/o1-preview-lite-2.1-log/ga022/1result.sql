WITH all_events AS (
  SELECT user_pseudo_id, event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
),

user_first_events AS (
  SELECT 
    user_pseudo_id,
    MIN(event_date) AS first_event_date
  FROM all_events
  GROUP BY user_pseudo_id
),

new_users AS (
  SELECT user_pseudo_id
  FROM user_first_events
  WHERE first_event_date BETWEEN '20180901' AND '20180907'
),

week_activity AS (
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN event_date BETWEEN '20180908' AND '20180914' THEN 1 ELSE 0 END) AS week1_active,
    MAX(CASE WHEN event_date BETWEEN '20180915' AND '20180921' THEN 1 ELSE 0 END) AS week2_active,
    MAX(CASE WHEN event_date BETWEEN '20180922' AND '20180928' THEN 1 ELSE 0 END) AS week3_active
  FROM all_events
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM new_users)
    AND event_date BETWEEN '20180908' AND '20180928'
  GROUP BY user_pseudo_id
),

retention_stats AS (
  SELECT
    (SELECT COUNT(*) FROM new_users) AS total_users,
    SUM(week1_active) AS week1_retained,
    SUM(week2_active) AS week2_retained,
    SUM(week3_active) AS week3_retained
  FROM week_activity
),

retention_rates AS (
  SELECT
    ROUND((week1_retained / total_users) * 100, 4) AS `Week1 Retention Rate`,
    ROUND((week2_retained / total_users) * 100, 4) AS `Week2 Retention Rate`,
    ROUND((week3_retained / total_users) * 100, 4) AS `Week3 Retention Rate`
  FROM retention_stats
)

SELECT * FROM retention_rates;