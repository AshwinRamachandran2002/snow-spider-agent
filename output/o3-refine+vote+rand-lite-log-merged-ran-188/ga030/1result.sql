-- Find the weekly‑cohort that shows the highest 4‑th‑week retention
WITH sessions AS (
  -- every session_start we have
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(event_timestamp)            AS event_ts,
    DATE(TIMESTAMP_MICROS(event_timestamp))      AS event_day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX >= '20180702'          -- only weeks we’re asked to analyse
),

-- each user’s very first session
first_session AS (
  SELECT
    user_pseudo_id,
    MIN(event_ts)                AS first_ts,
    DATE(MIN(event_ts))          AS first_day
  FROM sessions
  GROUP BY user_pseudo_id
),

-- build weekly cohorts (Monday‑based) starting 2018‑07‑02
cohorts AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_day, WEEK(MONDAY)) AS cohort_week
  FROM first_session
  WHERE first_day >= '2018-07-02'
),

-- any later session this user generated and the week it happened in
user_weeks AS (
  SELECT
    c.user_pseudo_id,
    c.cohort_week,
    DATE_TRUNC(s.event_day, WEEK(MONDAY)) AS session_week
  FROM sessions s
  JOIN cohorts  c
    ON c.user_pseudo_id = s.user_pseudo_id
),

-- did the user come back in the 4‑th week? (week starting cohort+21d)
wk4_return AS (
  SELECT DISTINCT
    user_pseudo_id,
    cohort_week
  FROM user_weeks
  WHERE session_week = DATE_ADD(cohort_week, INTERVAL 3 WEEK)   -- 0‑,1‑,2‑,3‑> fourth week
),

-- retention numbers for every cohort
retention AS (
  SELECT
    cohort_week,
    COUNT(DISTINCT c.user_pseudo_id)                     AS cohort_size,
    COUNT(DISTINCT r.user_pseudo_id)                     AS wk4_users,
    COUNT(DISTINCT r.user_pseudo_id)
      / COUNT(DISTINCT c.user_pseudo_id)                 AS wk4_rate
  FROM cohorts c
  LEFT JOIN wk4_return r USING (user_pseudo_id, cohort_week)
  GROUP BY cohort_week
),

-- pick the cohort with the highest 4‑th‑week retention rate
best_cohort AS (
  SELECT cohort_week
  FROM   retention
  ORDER  BY wk4_rate DESC, cohort_week     -- tie‑break by earlier week
  LIMIT  1
)

SELECT FORMAT_DATE('%F', cohort_week) AS cohort_monday
FROM   best_cohort;