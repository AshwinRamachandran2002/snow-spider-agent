WITH first_week_users AS (
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(MIN(event_timestamp)) AS first_event_time
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'
  GROUP BY user_pseudo_id
  HAVING first_event_time BETWEEN TIMESTAMP('2018-09-01 00:00:00', 'Asia/Shanghai') AND TIMESTAMP('2018-09-07 23:59:59', 'Asia/Shanghai')
),
user_events AS (
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(event_timestamp) AS event_time
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180908' AND '20180928'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM first_week_users)
),
user_retention AS (
  SELECT
    fwu.user_pseudo_id,
    MAX(CASE WHEN ue.event_time BETWEEN TIMESTAMP('2018-09-08 00:00:00', 'Asia/Shanghai') AND TIMESTAMP('2018-09-14 23:59:59', 'Asia/Shanghai') THEN 1 ELSE 0 END) AS week1_retained,
    MAX(CASE WHEN ue.event_time BETWEEN TIMESTAMP('2018-09-15 00:00:00', 'Asia/Shanghai') AND TIMESTAMP('2018-09-21 23:59:59', 'Asia/Shanghai') THEN 1 ELSE 0 END) AS week2_retained,
    MAX(CASE WHEN ue.event_time BETWEEN TIMESTAMP('2018-09-22 00:00:00', 'Asia/Shanghai') AND TIMESTAMP('2018-09-28 23:59:59', 'Asia/Shanghai') THEN 1 ELSE 0 END) AS week3_retained
  FROM first_week_users fwu
  LEFT JOIN user_events ue
    ON fwu.user_pseudo_id = ue.user_pseudo_id
  GROUP BY fwu.user_pseudo_id
),
totals AS (
  SELECT
    COUNT(*) AS total_users,
    SUM(week1_retained) AS week1_retained_count,
    SUM(week2_retained) AS week2_retained_count,
    SUM(week3_retained) AS week3_retained_count
  FROM user_retention
)
SELECT
  ROUND(week1_retained_count * 100.0 / total_users, 4) AS `Week1 Retention Rate`,
  ROUND(week2_retained_count * 100.0 / total_users, 4) AS `Week2 Retention Rate`,
  ROUND(week3_retained_count * 100.0 / total_users, 4) AS `Week3 Retention Rate`
FROM totals;