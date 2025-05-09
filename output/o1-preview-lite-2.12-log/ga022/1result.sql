WITH cohort AS (
  SELECT DISTINCT `user_pseudo_id`
  FROM (
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180901`
    UNION ALL
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180902`
    UNION ALL
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180903`
    UNION ALL
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180904`
    UNION ALL
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180905`
    UNION ALL
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180906`
    UNION ALL
    SELECT * FROM `firebase-public-project.analytics_153293282.events_20180907`
  )
  WHERE `event_name` = 'first_open'
    AND DATE(TIMESTAMP_MICROS(`event_timestamp` + 28800000000)) BETWEEN '2018-09-01' AND '2018-09-07'
),
events AS (
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180901`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180902`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180903`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180904`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180905`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180906`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180907`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180908`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180909`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180910`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180911`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180912`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180913`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180914`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180915`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180916`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180917`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180918`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180919`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180920`
  UNION ALL
  SELECT * FROM `firebase-public-project.analytics_153293282.events_20180921`
)
SELECT
  ROUND(100 * SUM(CASE WHEN active_week1 = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS Week1_RetentionRate,
  ROUND(100 * SUM(CASE WHEN active_week2 = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS Week2_RetentionRate,
  ROUND(100 * SUM(CASE WHEN active_week3 = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS Week3_RetentionRate
FROM (
  SELECT
    cohort.`user_pseudo_id`,
    MAX(CASE WHEN DATE(TIMESTAMP_MICROS(events.`event_timestamp` + 28800000000)) BETWEEN '2018-09-01' AND '2018-09-07' THEN 1 ELSE 0 END) AS active_week1,
    MAX(CASE WHEN DATE(TIMESTAMP_MICROS(events.`event_timestamp` + 28800000000)) BETWEEN '2018-09-08' AND '2018-09-14' THEN 1 ELSE 0 END) AS active_week2,
    MAX(CASE WHEN DATE(TIMESTAMP_MICROS(events.`event_timestamp` + 28800000000)) BETWEEN '2018-09-15' AND '2018-09-21' THEN 1 ELSE 0 END) AS active_week3
  FROM cohort
  LEFT JOIN events
    ON events.`user_pseudo_id` = cohort.`user_pseudo_id`
  GROUP BY cohort.`user_pseudo_id`
)