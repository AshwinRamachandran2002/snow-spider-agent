/* 7‑day (weekly) retention for users whose very first session_start was
   during the week that began on Monday, 2‑Jul‑2018.   
   – Week 0 = 02‑Jul‑2018 … 08‑Jul‑2018  
   – Week 1 … Week 4 follow in successive Monday‑based 7‑day windows  
   Only events through 02‑Oct‑2018 are considered. */

WITH sessions AS (                         -- every session_start we care about
  SELECT
    user_pseudo_id,
    DATE(PARSE_DATE('%Y%m%d', event_date)) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'   -- scan only needed days
),

first_sessions AS (                        -- first‑ever session per user
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM sessions
  GROUP BY user_pseudo_id
),

cohort AS (                                -- keep users whose first session was 02‑Jul‑2018 week
  SELECT
    user_pseudo_id,
    first_session_date,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week_monday
  FROM first_sessions
  WHERE first_session_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),

cohort_sessions AS (                       -- all later sessions for those cohort users
  SELECT
    c.user_pseudo_id,
    DATE_TRUNC(s.event_date, WEEK(MONDAY))      AS session_week_monday,
    c.cohort_week_monday
  FROM cohort            AS c
  JOIN sessions           AS s
    ON s.user_pseudo_id = c.user_pseudo_id
  WHERE s.event_date <= DATE '2018-10-02'
),

retention AS (                             -- week index (0‑4) for every cohort user/session
  SELECT DISTINCT
    DATE_DIFF(session_week_monday, cohort_week_monday, WEEK(MONDAY)) AS week_number,
    user_pseudo_id
  FROM cohort_sessions
  WHERE DATE_DIFF(session_week_monday, cohort_week_monday, WEEK(MONDAY)) BETWEEN 0 AND 4
)

SELECT
  week_number                         AS week,
  CASE WHEN week_number = 0
       THEN COUNT(DISTINCT user_pseudo_id)
  END                                 AS new_users_week0,
  COUNT(DISTINCT user_pseudo_id)      AS retained_users
FROM retention
GROUP BY week_number
ORDER BY week_number;