WITH first_session AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX >= '20180702'          -- start from 2 July 2018
  GROUP BY user_pseudo_id
),
cohort_users AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_dt, WEEK(MONDAY)) AS cohort_start
  FROM first_session
  WHERE first_session_dt >= DATE '2018-07-02' -- ignore earlier cohorts
),
cohort_sizes AS (
  SELECT
    cohort_start,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size
  FROM cohort_users
  GROUP BY cohort_start
),
returns_wk4 AS (
  SELECT DISTINCT
    cu.cohort_start,
    s.user_pseudo_id
  FROM cohort_users cu
  JOIN `firebase-public-project.analytics_153293282.events_*` s
    ON s.user_pseudo_id = cu.user_pseudo_id
  WHERE s.event_name = 'session_start'
    AND _TABLE_SUFFIX >= '20180702'
    AND PARSE_DATE('%Y%m%d', s.event_date)
        BETWEEN DATE_ADD(cu.cohort_start, INTERVAL 21 DAY)
            AND DATE_ADD(cu.cohort_start, INTERVAL 27 DAY)
),
wk4_counts AS (
  SELECT
    cohort_start,
    COUNT(DISTINCT user_pseudo_id) AS returned_wk4
  FROM returns_wk4
  GROUP BY cohort_start
),
retention AS (
  SELECT
    cs.cohort_start,
    SAFE_DIVIDE(wk.returned_wk4, cs.cohort_size) AS retention_wk4
  FROM cohort_sizes cs
  LEFT JOIN wk4_counts wk
    USING (cohort_start)
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_start) AS best_cohort_monday
FROM retention
ORDER BY retention_wk4 DESC
LIMIT 1;