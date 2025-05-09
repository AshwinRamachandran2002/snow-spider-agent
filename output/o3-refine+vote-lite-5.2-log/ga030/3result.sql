-- Cohort with the highest 4‑th‑week retention (Monday date of the cohort)
WITH sessions AS (     -- every session_start event we have
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_day          -- local date of the event
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
),

cohorts AS (           -- first session week (cohort) for every user
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(event_day), WEEK(MONDAY)) AS cohort_monday
  FROM sessions
  GROUP BY user_pseudo_id
  HAVING cohort_monday >= DATE '2018-07-02'                -- only cohorts asked for
),

cohort_size AS (       -- number of users in every cohort
  SELECT cohort_monday,
         COUNT(DISTINCT user_pseudo_id) AS users_in_cohort
  FROM cohorts
  GROUP BY cohort_monday
),

week4_returns AS (     -- users that returned in the 4‑th week (days 21‑27)
  SELECT
    c.cohort_monday,
    COUNT(DISTINCT s.user_pseudo_id) AS users_returned_w4
  FROM cohorts AS c
  JOIN sessions AS s
    ON s.user_pseudo_id = c.user_pseudo_id
   AND DATE_DIFF(s.event_day, c.cohort_monday, DAY) BETWEEN 21 AND 27
  GROUP BY c.cohort_monday
),

retention AS (         -- 4‑th‑week retention rate for every cohort
  SELECT
    cs.cohort_monday,
    SAFE_DIVIDE(IFNULL(w4.users_returned_w4,0), cs.users_in_cohort) AS w4_retention
  FROM cohort_size AS cs
  LEFT JOIN week4_returns AS w4
  USING (cohort_monday)
)

SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_monday) AS cohort_monday_with_best_w4_retention
FROM retention
ORDER BY w4_retention DESC, cohort_monday
LIMIT 1;