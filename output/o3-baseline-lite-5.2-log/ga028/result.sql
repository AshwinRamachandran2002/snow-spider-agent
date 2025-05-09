/* 7‑day retention – cohort whose very first session_start was during
   the Monday‑based week that begins on 2‑Jul‑2018                  */

WITH sessions AS (
  -- every session_start we care about (from 2‑Jul‑2018 to 2‑Oct‑2018)
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt          -- convert to DATE
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'   -- only needed tables
    AND event_name = 'session_start'
),

first_sessions AS (
  -- first ever session_start per user
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_session_dt
  FROM sessions
  GROUP BY user_pseudo_id
),

cohort AS (
  -- cohort = users whose first session fell in the week 2‑Jul‑2018 … 8‑Jul‑2018
  SELECT
    user_pseudo_id
  FROM first_sessions
  WHERE first_session_dt BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),

retention AS (
  -- tag each cohort user‑session with the week index (Week 0 … Week 4)
  SELECT
    s.user_pseudo_id,
    DIV(DATE_DIFF(s.event_dt, DATE '2018-07-02', DAY), 7) AS week_idx
  FROM sessions s
  JOIN cohort  USING (user_pseudo_id)
  WHERE s.event_dt <= DATE '2018-10-02'                -- ignore events after 2‑Oct‑2018
    AND DIV(DATE_DIFF(s.event_dt, DATE '2018-07-02', DAY), 7) BETWEEN 0 AND 4
)

-- final 7‑day retention table
SELECT
  CONCAT('Week_', CAST(week_idx AS STRING)) AS week,
  COUNT(DISTINCT user_pseudo_id)          AS users_retained
FROM retention
GROUP BY week_idx
ORDER BY week_idx;