-- 7‑day (weekly) retention for users whose very first session
-- happened during the week that starts on Monday 2 July 2018
-- (only events up to 02‑Oct‑2018 are taken into account)

WITH session_events AS (                       -- every session_start we will look at
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181002'      -- scan only needed tables
),

first_sessions AS (                           -- first‑ever session date for each user
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_session_date
  FROM session_events
  GROUP BY user_pseudo_id
),

cohort_users AS (                             -- users whose first session falls in 2‑Jul‑2018 week
  SELECT
    user_pseudo_id
  FROM
    first_sessions
  WHERE
    first_session_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),

cohort_activity AS (                          -- activity of those users, mapped to week index
  SELECT
    se.user_pseudo_id,
    DIV(DATE_DIFF(se.event_dt, DATE '2018-07-02', DAY), 7) AS week_index   -- 0 = week of 2‑Jul‑2018
  FROM
    session_events se
    JOIN cohort_users cu USING (user_pseudo_id)
  WHERE
    se.event_dt <= DATE '2018-10-02'                               -- ignore events after 02‑Oct‑2018
),

retained AS (                                 -- how many of them were active each week
  SELECT
    week_index,
    COUNT(DISTINCT user_pseudo_id) AS users_retained
  FROM
    cohort_activity
  WHERE
    week_index BETWEEN 0 AND 4                                    -- Week 0 .. Week 4
  GROUP BY week_index
),

weeks AS (                                    -- guarantee all five weeks appear
  SELECT 0 AS week_index UNION ALL
  SELECT 1 UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4
)

SELECT
  w.week_index,
  CASE
    WHEN w.week_index = 0
      THEN (SELECT COUNT(*) FROM cohort_users)       -- cohort size (new users)
    ELSE COALESCE(r.users_retained, 0)               -- retained users for Week 1‑4
  END AS user_count
FROM
  weeks w
  LEFT JOIN retained r USING (week_index)
ORDER BY
  week_index;