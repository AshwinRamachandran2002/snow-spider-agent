WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) AS event_date,
    user_pseudo_id,
    event_name
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'                       -- data window
),
cohort AS (                                                                   -- users whose first session is 2‑8 Jul 2018
  SELECT
    user_pseudo_id,
    MIN(event_date) AS cohort_date
  FROM base
  WHERE event_name = 'session_start'
    AND event_date BETWEEN '2018-07-02' AND '2018-07-08'
  GROUP BY user_pseudo_id
),
events AS (                                                                   -- all cohort users’ events up to 2‑Oct‑2018
  SELECT
    b.user_pseudo_id,
    DATE_DIFF(b.event_date, c.cohort_date, WEEK(MONDAY)) AS week_number
  FROM base b
  JOIN cohort c USING (user_pseudo_id)
  WHERE b.event_date <= '2018-10-02'
    AND DATE_DIFF(b.event_date, c.cohort_date, WEEK(MONDAY)) BETWEEN 0 AND 4  -- Week 0–4 only
)
SELECT
  week_number AS week,                                                        -- 0 … 4 (Monday‑based)
  (SELECT COUNT(*) FROM cohort)     AS cohort_size,                           -- constant = new users in Week 0
  COUNT(DISTINCT user_pseudo_id)    AS retained_users                         -- users active during the week
FROM events
GROUP BY week
ORDER BY week;