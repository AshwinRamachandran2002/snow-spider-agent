WITH first_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS first_session_week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_date >= '20180702'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
fourth_week_events AS (
  SELECT DISTINCT
    e.user_pseudo_id,
    fs.first_session_week
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  INNER JOIN first_sessions AS fs
    ON e.user_pseudo_id = fs.user_pseudo_id
  WHERE PARSE_DATE('%Y%m%d', e.event_date) BETWEEN
    DATE_ADD(fs.first_session_week, INTERVAL 21 DAY) AND
    DATE_ADD(fs.first_session_week, INTERVAL 27 DAY)
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_week) AS `YYYY-MM-DD`
FROM (
  SELECT
    fs.first_session_week AS cohort_week,
    COUNT(DISTINCT fs.user_pseudo_id) AS cohort_size,
    COUNT(DISTINCT fw.user_pseudo_id) AS retained_users,
    SAFE_DIVIDE(COUNT(DISTINCT fw.user_pseudo_id), COUNT(DISTINCT fs.user_pseudo_id)) AS retention_rate
  FROM first_sessions fs
  LEFT JOIN fourth_week_events fw
    ON fs.user_pseudo_id = fw.user_pseudo_id
    AND fs.first_session_week = fw.first_session_week
  GROUP BY fs.first_session_week
  ORDER BY retention_rate DESC
  LIMIT 1
)