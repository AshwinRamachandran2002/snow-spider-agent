-- Cohort with the highest fourth‑week retention (Monday date returned)
WITH session_events AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt         -- convert to DATE
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    event_name = 'session_start'
    -- consider only data from the first cohort start onward
    AND event_date >= '20180702'
),

-- first session of every user (cohort entry)
first_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_session_dt
  FROM session_events
  GROUP BY user_pseudo_id
),

-- assign every user to the Monday of their first‑session week
cohort_users AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_dt, WEEK(MONDAY)) AS cohort_monday
  FROM first_sessions
),

-- size of each cohort (distinct users)
cohort_sizes AS (
  SELECT
    cohort_monday,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size
  FROM cohort_users
  GROUP BY cohort_monday
),

-- users who generated a session in the 4‑th week after their cohort week
week4_returns AS (
  SELECT
    cu.cohort_monday,
    COUNT(DISTINCT cu.user_pseudo_id) AS week4_users
  FROM cohort_users cu
  JOIN session_events se
    ON se.user_pseudo_id = cu.user_pseudo_id
  WHERE
    DATE_DIFF(se.event_dt, cu.cohort_monday, WEEK(MONDAY)) = 4   -- 4‑th week
  GROUP BY cu.cohort_monday
),

-- retention rates
retention AS (
  SELECT
    cs.cohort_monday,
    cs.cohort_size,
    COALESCE(w4.week4_users, 0) AS week4_users,
    SAFE_DIVIDE(COALESCE(w4.week4_users,0), cs.cohort_size) AS retention_rate
  FROM cohort_sizes cs
  LEFT JOIN week4_returns w4
    ON cs.cohort_monday = w4.cohort_monday
)

-- pick the cohort with the highest 4‑th week retention
SELECT
  FORMAT_DATE('%F', cohort_monday) AS cohort_start_monday
FROM retention
ORDER BY retention_rate DESC, cohort_monday
LIMIT 1;