-- Cohort‑based 4‑week retention and cohort with the highest week‑4 retention
WITH sessions AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)          AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'           -- limit to available range
    AND event_name = 'session_start'
),

-- first session (cohort entry) per user, starting 2‑Jul‑2018 (a Monday)
first_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(event_date)                           AS first_session_date
  FROM sessions
  GROUP BY user_pseudo_id
  HAVING first_session_date >= DATE '2018-07-02'
),

-- assign each user to a Monday‑based cohort week
cohorts AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_monday
  FROM first_sessions
),

-- users who returned in the 4th week (days 22‑28 after first session)
week4_returns AS (
  SELECT DISTINCT s.user_pseudo_id
  FROM sessions s
  JOIN first_sessions f
    ON f.user_pseudo_id = s.user_pseudo_id
  WHERE DATE_DIFF(s.event_date, f.first_session_date, DAY) BETWEEN 22 AND 28
),

-- cohort sizes and 4‑week returning users
cohort_stats AS (
  SELECT
    c.cohort_monday,
    COUNT(DISTINCT c.user_pseudo_id)               AS cohort_size,
    COUNT(DISTINCT w.user_pseudo_id)               AS week4_returning,
    SAFE_DIVIDE(COUNT(DISTINCT w.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id))  AS week4_retention_rate
  FROM cohorts c
  LEFT JOIN week4_returns w
    ON c.user_pseudo_id = w.user_pseudo_id
  GROUP BY c.cohort_monday
)

-- return the Monday date of the cohort with the highest 4‑week retention
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_monday) AS cohort_week_start
FROM cohort_stats
ORDER BY week4_retention_rate DESC, cohort_monday      -- tie‑breaker: earliest week
LIMIT 1;