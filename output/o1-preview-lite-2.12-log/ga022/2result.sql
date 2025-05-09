WITH cohort_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
    AND FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')) BETWEEN '20180901' AND '20180907'
),
total_cohort_users AS (
  SELECT COUNT(*) AS total_users FROM cohort_users
),
week1_users AS (
  SELECT COUNT(DISTINCT user_pseudo_id) AS returning_users_week1
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
    AND FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')) BETWEEN '20180908' AND '20180914'
),
week2_users AS (
  SELECT COUNT(DISTINCT user_pseudo_id) AS returning_users_week2
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
    AND FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')) BETWEEN '20180915' AND '20180921'
),
week3_users AS (
  SELECT COUNT(DISTINCT user_pseudo_id) AS returning_users_week3
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
    AND FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')) BETWEEN '20180922' AND '20180928'
)
SELECT
  ROUND(100.0 * week1_users.returning_users_week1 / total_cohort_users.total_users, 4) AS Week1_RetentionRate,
  ROUND(100.0 * week2_users.returning_users_week2 / total_cohort_users.total_users, 4) AS Week2_RetentionRate,
  ROUND(100.0 * week3_users.returning_users_week3 / total_cohort_users.total_users, 4) AS Week3_RetentionRate
FROM total_cohort_users, week1_users, week2_users, week3_users;