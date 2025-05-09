WITH first_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND PARSE_DATE('%Y%m%d', event_date) >= '2018-07-02'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'
  GROUP BY user_pseudo_id
),
user_cohorts AS (
  SELECT
    user_pseudo_id,
    first_session_date,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week_start
  FROM first_sessions
),
cohort_sizes AS (
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS total_users
  FROM user_cohorts
  GROUP BY cohort_week_start
),
week4_returns AS (
  SELECT
    u.cohort_week_start,
    u.user_pseudo_id
  FROM user_cohorts u
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON u.user_pseudo_id = e.user_pseudo_id
  WHERE
    PARSE_DATE('%Y%m%d', e.event_date) BETWEEN DATE_ADD(u.first_session_date, INTERVAL 28 DAY) AND DATE_ADD(u.first_session_date, INTERVAL 34 DAY)
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_ADD('2018-07-02', INTERVAL 28 DAY)) AND '20181003'
),
cohort_returns AS (
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS returned_users
  FROM week4_returns
  GROUP BY cohort_week_start
),
cohort_retention AS (
  SELECT
    s.cohort_week_start,
    s.total_users,
    r.returned_users,
    SAFE_DIVIDE(r.returned_users, s.total_users) AS retention_rate
  FROM cohort_sizes s
  LEFT JOIN cohort_returns r USING(cohort_week_start)
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_week_start) AS cohort_week_start
FROM cohort_retention
ORDER BY retention_rate DESC, cohort_week_start
LIMIT 1