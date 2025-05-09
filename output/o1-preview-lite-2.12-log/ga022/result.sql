WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    TIMESTAMP_MICROS(event_timestamp + 8 * 3600 * 1000000) AS event_shanghai_time,
    FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp + 8 * 3600 * 1000000))) AS event_date_shanghai
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180831' AND '20180929'
),
first_open_events AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_open_timestamp
  FROM events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),
new_users AS (
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(first_open_timestamp + 8 * 3600 * 1000000) AS first_open_shanghai_time,
    FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(first_open_timestamp + 8 * 3600 * 1000000))) AS first_open_date_shanghai
  FROM first_open_events
  WHERE FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(first_open_timestamp + 8 * 3600 * 1000000))) BETWEEN '20180901' AND '20180907'
),
user_weekly_flags AS (
  SELECT
    nu.user_pseudo_id,
    MAX(CASE WHEN e.event_date_shanghai BETWEEN '20180908' AND '20180914' THEN 1 ELSE 0 END) AS week1_active,
    MAX(CASE WHEN e.event_date_shanghai BETWEEN '20180915' AND '20180921' THEN 1 ELSE 0 END) AS week2_active,
    MAX(CASE WHEN e.event_date_shanghai BETWEEN '20180922' AND '20180928' THEN 1 ELSE 0 END) AS week3_active
  FROM new_users nu
  LEFT JOIN events e
    ON nu.user_pseudo_id = e.user_pseudo_id
  GROUP BY nu.user_pseudo_id
)
SELECT
  ROUND(100.0 * SUM(week1_active) / COUNT(user_pseudo_id), 4) AS Week1_RetentionRate,
  ROUND(100.0 * SUM(week2_active) / COUNT(user_pseudo_id), 4) AS Week2_RetentionRate,
  ROUND(100.0 * SUM(week3_active) / COUNT(user_pseudo_id), 4) AS Week3_RetentionRate
FROM user_weekly_flags;