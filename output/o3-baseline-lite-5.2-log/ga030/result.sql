-- Cohort with the highest 4‑th week retention, labelled by the Monday of the cohort week
WITH all_session_starts AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date)               AS event_dt,
    user_pseudo_id
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180702' AND '20181031'   -- data range to cover cohorts + 4 weeks
    AND event_name = 'session_start'
),

-- first session (cohort entrance) for each user, starting 2 Jul 2018
first_session AS (
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_session_date
  FROM all_session_starts
  GROUP BY user_pseudo_id
  HAVING first_session_date >= DATE '2018-07-02'
),

-- assign users to Monday‑based cohort
user_cohort AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_monday
  FROM first_session
),

-- every session_start tagged with the user’s cohort
events_with_cohort AS (
  SELECT
    s.user_pseudo_id,
    c.cohort_monday,
    s.event_dt,
    DATE_DIFF(s.event_dt, c.cohort_monday, WEEK) AS week_index          -- 0 = cohort week
  FROM all_session_starts s
  JOIN user_cohort       c USING (user_pseudo_id)
),

-- size of each cohort
cohort_size AS (
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id) AS users_in_cohort
  FROM user_cohort
  GROUP BY cohort_monday
),

-- users who came back in the 4‑th week (week_index = 3)
week4_returners AS (
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id) AS users_returned_wk4
  FROM events_with_cohort
  WHERE week_index = 3
  GROUP BY cohort_monday
),

-- retention rate per cohort
cohort_retention AS (
  SELECT
    cs.cohort_monday,
    COALESCE(w4.users_returned_wk4, 0)            AS users_returned_wk4,
    cs.users_in_cohort,
    COALESCE(w4.users_returned_wk4, 0) / cs.users_in_cohort AS wk4_retention
  FROM cohort_size cs
  LEFT JOIN week4_returners w4 USING (cohort_monday)
)

-- cohort with the highest 4‑th week retention
SELECT
  FORMAT_DATE('%F', cohort_monday) AS cohort_monday
FROM cohort_retention
ORDER BY wk4_retention DESC
LIMIT 1;