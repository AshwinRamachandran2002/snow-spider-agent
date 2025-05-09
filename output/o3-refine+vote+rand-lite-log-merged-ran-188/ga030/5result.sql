WITH sessions AS (
  -- all session_start events from 2‑Jul‑2018 onward
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX >= '20180702'
    AND event_name = 'session_start'
),
first_session AS (
  -- first session date per user (cohort entry date)
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM sessions
  GROUP BY user_pseudo_id
  HAVING first_session_date >= DATE '2018-07-02'
),
activity AS (
  -- every session for users whose first session ≥ 2‑Jul‑2018
  SELECT
    s.user_pseudo_id,
    DATE_TRUNC(f.first_session_date, WEEK(MONDAY)) AS cohort_monday,
    DATE_DIFF(s.event_date, f.first_session_date, DAY) AS days_since_first
  FROM sessions s
  JOIN first_session f
    ON s.user_pseudo_id = f.user_pseudo_id
),
cohort_metrics AS (
  -- cohort size and 4‑th‑week retained users (22‑28 days after first session)
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id)                                               AS cohort_users,
    COUNT(DISTINCT IF(days_since_first BETWEEN 22 AND 28, user_pseudo_id, NULL)) AS retained_wk4
  FROM activity
  GROUP BY cohort_monday
),
ranked AS (
  -- rank cohorts by week‑4 retention rate
  SELECT
    cohort_monday,
    SAFE_DIVIDE(retained_wk4, cohort_users) AS wk4_retention,
    ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(retained_wk4, cohort_users) DESC,
                               cohort_monday) AS rn
  FROM cohort_metrics
)
-- cohort (Monday date) with the highest 4‑th‑week retention
SELECT FORMAT_DATE('%Y-%m-%d', cohort_monday) AS cohort_monday
FROM ranked
WHERE rn = 1;