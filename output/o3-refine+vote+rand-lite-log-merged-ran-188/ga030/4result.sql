WITH first_sessions AS (
  -- first session (cohort‑defining) for every user on/after 2‑Jul‑2018
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX >= '20180702'          -- only tables from 2‑Jul‑2018 onward
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
cohorts AS (
  -- assign each user to the Monday of the week of his/her first session
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_monday
  FROM first_sessions
  WHERE first_session_date >= DATE '2018-07-02'
),
week4_returns AS (
  -- any session_start that occurs in the 4th week AFTER the cohort week
  SELECT
    c.user_pseudo_id,
    c.cohort_monday
  FROM cohorts c
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND _TABLE_SUFFIX >= '20180702'
    -- difference in weeks (0 = cohort week, 4 = 4th week after)
    AND DIV(DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date),
                      c.cohort_monday,
                      DAY), 7) = 4
),
cohort_sizes AS (
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id) AS cohort_users
  FROM cohorts
  GROUP BY cohort_monday
),
return_sizes AS (
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id) AS returned_users_wk4
  FROM week4_returns
  GROUP BY cohort_monday
),
retention AS (
  SELECT
    cs.cohort_monday,
    SAFE_DIVIDE(COALESCE(rs.returned_users_wk4, 0), cs.cohort_users) AS wk4_retention
  FROM cohort_sizes cs
  LEFT JOIN return_sizes rs
  USING (cohort_monday)
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_monday) AS cohort_monday
FROM retention
ORDER BY wk4_retention DESC, cohort_monday
LIMIT 1;