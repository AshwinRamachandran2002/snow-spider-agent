-- Cohort (week‑of‑first‑session) with the highest 4th‑week retention
WITH sessions AS (
  -- every session_start from 2 July 2018 onward
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20181031'   -- limits scan range
    AND event_date >= '20180702'
),

first_sessions AS (
  -- first session date per user
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_dt
  FROM sessions
  GROUP BY user_pseudo_id
),

cohorted_users AS (
  -- assign each user to the Monday of their first‑session week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_dt, WEEK(MONDAY)) AS cohort_monday
  FROM first_sessions
  WHERE first_dt >= '2018-07-02'
),

cohort_sizes AS (
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id) AS cohort_users
  FROM cohorted_users
  GROUP BY cohort_monday
),

week4_returns AS (
  -- users who came back in days 22‑28 (4th week) after first session
  SELECT
    cu.cohort_monday,
    COUNT(DISTINCT cu.user_pseudo_id) AS week4_users
  FROM cohorted_users cu
  JOIN sessions s
    ON s.user_pseudo_id = cu.user_pseudo_id
  JOIN first_sessions f
    ON f.user_pseudo_id = cu.user_pseudo_id
  WHERE DATE_DIFF(s.event_dt, f.first_dt, DAY) BETWEEN 22 AND 28
  GROUP BY cu.cohort_monday
),

retention AS (
  SELECT
    cs.cohort_monday,
    COALESCE(week4_users, 0) / cs.cohort_users AS week4_retention
  FROM cohort_sizes cs
  LEFT JOIN week4_returns wr
    USING (cohort_monday)
)

SELECT FORMAT_DATE('%F', cohort_monday) AS cohort_monday
FROM retention
ORDER BY week4_retention DESC, cohort_monday
LIMIT 1;