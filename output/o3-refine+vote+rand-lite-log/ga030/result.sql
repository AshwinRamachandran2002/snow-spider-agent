-- cohort with the highest 4‑th week retention
WITH sessions AS (
  -- all “session_start” events we will need
  SELECT
    user_pseudo_id,
    DATE(PARSE_DATE('%Y%m%d', event_date)) AS event_date
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'  -- keep the period wide enough
    AND event_name = 'session_start'
),
first_session AS (
  -- each user’s first visit (only users whose first visit is on/after 2‑Jul‑2018)
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM sessions
  GROUP BY user_pseudo_id
  HAVING first_session_date >= '2018-07-02'
),
cohort_users AS (
  -- assign every user to a Monday‑based cohort
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week_start
  FROM first_session
),
returns AS (
  -- all subsequent sessions for those users and the week index (0,1,2…)
  SELECT
    cu.user_pseudo_id,
    cu.cohort_week_start,
    s.event_date,
    DIV(DATE_DIFF(s.event_date, cu.cohort_week_start, DAY), 7) AS week_index
  FROM cohort_users cu
  JOIN sessions s
  USING (user_pseudo_id)
),
fourth_week_users AS (
  -- users who came back in the 4‑th week after their cohort week
  SELECT DISTINCT
    user_pseudo_id,
    cohort_week_start
  FROM returns
  WHERE week_index = 4          -- 0 = cohort week, 4 = 4‑th week after
),
cohort_stats AS (
  -- retention calculation for every cohort
  SELECT
    cohort_week_start,
    COUNT(DISTINCT cu.user_pseudo_id)                       AS cohort_size,
    COUNT(DISTINCT fw.user_pseudo_id)                       AS returned_in_week4,
    SAFE_DIVIDE(COUNT(DISTINCT fw.user_pseudo_id),
                COUNT(DISTINCT cu.user_pseudo_id))          AS week4_retention
  FROM cohort_users cu
  LEFT JOIN fourth_week_users fw
  USING (user_pseudo_id, cohort_week_start)
  GROUP BY cohort_week_start
),
best_cohort AS (
  -- cohort with the best 4‑th week retention
  SELECT cohort_week_start
  FROM cohort_stats
  ORDER BY week4_retention DESC, cohort_week_start
  LIMIT 1
)
SELECT FORMAT_DATE('%Y-%m-%d', cohort_week_start) AS cohort_monday_date
FROM best_cohort;