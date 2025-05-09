-- 7‑day (weekly) retention for users whose very first session was in the
-- Monday‑based week that starts on 02‑Jul‑2018.
--
-- Week_number = 0 → cohort creation week
-- Week_number = 1‑4 → users that came back in the 1st, 2nd, 3rd, and 4th
--                    weeks after the cohort week
--
-- The query only looks at events up to (and including) 02‑Oct‑2018.

WITH session_start_events AS (                      -- every session_start we’ll need
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX <= '20181002'                -- safety limit
),

first_session_per_user AS (                        -- first‑ever session per user
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM session_start_events
  GROUP BY user_pseudo_id
),

cohort AS (                                        -- users whose first session fell
  SELECT                                           -- in the week 02‑Jul‑2018 → 08‑Jul‑2018
    user_pseudo_id,
    DATE_TRUNC(first_session_date , WEEK(MONDAY)) AS cohort_week_start
  FROM first_session_per_user
  WHERE first_session_date BETWEEN '2018-07-02' AND '2018-07-08'
),

cohort_sessions AS (                               -- every later session for cohort users
  SELECT
    c.user_pseudo_id,
    DATE_TRUNC(s.event_date , WEEK(MONDAY))  AS event_week_start,
    DATE_TRUNC(c.cohort_week_start , WEEK(MONDAY)) AS cohort_week_start
  FROM cohort               AS c
  JOIN session_start_events AS s
    ON c.user_pseudo_id = s.user_pseudo_id
  WHERE s.event_date <= '2018-10-02'              -- limit analysis window
),

retention AS (                                    -- week index of each session
  SELECT
    DATE_DIFF(event_week_start , cohort_week_start , WEEK(MONDAY)) AS week_number,
    user_pseudo_id
  FROM cohort_sessions
  WHERE DATE_DIFF(event_week_start , cohort_week_start , WEEK(MONDAY)) BETWEEN 0 AND 4
)

-- final result -------------------------------------------------------------
SELECT
  0                                            AS week_number,
  COUNT(DISTINCT user_pseudo_id)               AS new_users,
  COUNT(DISTINCT user_pseudo_id)               AS retained_users
FROM cohort                                     -- Week 0 (cohort size)

UNION ALL

SELECT                                         -- Weeks 1‑4 (retained users)
  week_number,
  NULL                                         AS new_users,
  COUNT(DISTINCT user_pseudo_id)               AS retained_users
FROM retention
WHERE week_number BETWEEN 1 AND 4
GROUP BY week_number
ORDER BY week_number;