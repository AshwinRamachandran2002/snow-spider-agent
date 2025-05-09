/* 7‑day retention (Monday‑based weeks) for users whose first
   session_start happened in the week that began on 2018‑07‑02   */

WITH sessions AS (        -- every session_start we care about
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'      -- limit to data available
    AND event_name = 'session_start'
),

cohort AS (               -- users whose very first session_start was week of 2018‑07‑02
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(event_dt), WEEK(MONDAY)) AS cohort_week_start
  FROM sessions
  GROUP BY user_pseudo_id
  HAVING cohort_week_start = DATE '2018-07-02'
),

retention AS (            -- weeks (0‑4) in which each cohort user returned
  SELECT
    s.user_pseudo_id,
    DATE_DIFF(
      DATE_TRUNC(s.event_dt, WEEK(MONDAY)),
      c.cohort_week_start,
      WEEK(MONDAY)
    ) AS week_number
  FROM sessions s
  JOIN cohort  c USING (user_pseudo_id)
  WHERE DATE_DIFF(
          DATE_TRUNC(s.event_dt, WEEK(MONDAY)),
          c.cohort_week_start,
          WEEK(MONDAY)
        ) BETWEEN 0 AND 4
)

-- assemble counts
SELECT
  week_number,
  COUNT(DISTINCT user_pseudo_id) AS retained_users
FROM (
  -- Week 0 (cohort size)
  SELECT 0 AS week_number, user_pseudo_id FROM cohort
  UNION ALL
  -- Weeks 1‑4 (retention)
  SELECT week_number, user_pseudo_id
  FROM   retention
  WHERE  week_number BETWEEN 1 AND 4
)
GROUP BY week_number
ORDER BY week_number;