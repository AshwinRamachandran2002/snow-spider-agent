/* 7‑day retention (Week‑0 … Week‑4) for users whose very first
   session took place in the Monday‑based week that starts 2018‑07‑02.
   Only events up to (and including) 2018‑10‑02 are considered.          */

WITH session_events AS (     -- every “session_start” we care about
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180601' AND '20181002'
    AND event_name = 'session_start'
),

first_session_per_user AS (  -- first ever session of each user
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM session_events
  GROUP BY user_pseudo_id
),

cohort AS (                  -- users whose first session is 2018‑07‑02 … 2018‑07‑08
  SELECT user_pseudo_id
  FROM first_session_per_user
  WHERE first_session_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),

cohort_sessions AS (         -- all sessions these cohort users have (≤ 2018‑10‑02)
  SELECT
    se.user_pseudo_id,
    se.event_date,
    -- Week index: 0 = cohort week, 1 = next week, … (Monday‑based)
    FLOOR(DATE_DIFF(se.event_date, DATE '2018-07-02', DAY) / 7) AS week_index
  FROM session_events AS se
  JOIN cohort         AS c  USING (user_pseudo_id)
  WHERE se.event_date <= DATE '2018-10-02'
)

SELECT
  week_index                    AS week_number,          -- 0 … 4
  COUNT(DISTINCT user_pseudo_id) AS users_in_week        -- Week‑0 = new users; others = retained
FROM cohort_sessions
WHERE week_index BETWEEN 0 AND 4
GROUP BY week_number
ORDER BY week_number;