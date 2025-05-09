WITH cohort_events AS (
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180901`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180902`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180903`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180904`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180905`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180906`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180907`
),
cohort_users AS (
  SELECT user_pseudo_id
  FROM (
    SELECT
      user_pseudo_id,
      MIN(DATETIME(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')) AS first_event_time
    FROM cohort_events
    GROUP BY user_pseudo_id
  )
  WHERE first_event_time BETWEEN '2018-09-01' AND '2018-09-07 23:59:59'
),
week1_events AS (
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180908`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180909`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180910`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180911`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180912`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180913`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180914`
),
week1_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM week1_events
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
    AND DATETIME(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai') BETWEEN '2018-09-08' AND '2018-09-14 23:59:59'
),
week2_events AS (
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180915`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180916`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180917`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180918`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180919`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180920`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180921`
),
week2_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM week2_events
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
    AND DATETIME(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai') BETWEEN '2018-09-15' AND '2018-09-21 23:59:59'
),
week3_events AS (
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180922`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180923`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180924`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180925`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180926`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180927`
  UNION ALL
  SELECT user_pseudo_id, event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_20180928`
),
week3_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM week3_events
  WHERE user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
    AND DATETIME(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai') BETWEEN '2018-09-22' AND '2018-09-28 23:59:59'
),
total_users AS (
  SELECT COUNT(DISTINCT user_pseudo_id) AS total_users FROM cohort_users
)

SELECT
  ROUND((SELECT COUNT(*) FROM week1_users)*100.0/total_users.total_users, 4) AS `Week1 Retention Rate`,
  ROUND((SELECT COUNT(*) FROM week2_users)*100.0/total_users.total_users, 4) AS `Week2 Retention Rate`,
  ROUND((SELECT COUNT(*) FROM week3_users)*100.0/total_users.total_users, 4) AS `Week3 Retention Rate`
FROM total_users