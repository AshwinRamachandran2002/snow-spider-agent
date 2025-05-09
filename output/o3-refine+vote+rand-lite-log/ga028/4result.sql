-- 7‑day (Monday‑based) retention for users whose very first
-- session_start happened in the week that starts on 2018‑07‑02

WITH session_events AS (   -- every session_start we will use
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181002'      -- scan only what we need
    AND event_name = 'session_start'
),

cohort AS (                -- users whose *first‑ever* session_start is 2018‑07‑02 week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(event_date), WEEK(MONDAY)) AS cohort_week_start
  FROM session_events
  GROUP BY user_pseudo_id
  HAVING cohort_week_start = DATE '2018-07-02'
),

activity AS (              -- all later session_starts for those cohort users
  SELECT
    s.user_pseudo_id,
    DATE_TRUNC(s.event_date, WEEK(MONDAY)) AS activity_week_start,
    c.cohort_week_start
  FROM session_events AS s
  JOIN cohort        AS c
    ON s.user_pseudo_id = c.user_pseudo_id
  WHERE s.event_date <= DATE '2018-10-02'                    -- don’t look past 2 Oct 2018
),

retention_raw AS (         -- how many cohort users appeared in each week 0‑4
  SELECT
    CAST(DATE_DIFF(activity_week_start, cohort_week_start, DAY) / 7 AS INT64) AS week_index,
    COUNT(DISTINCT user_pseudo_id) AS users
  FROM activity
  WHERE CAST(DATE_DIFF(activity_week_start, cohort_week_start, DAY) / 7 AS INT64) BETWEEN 0 AND 4
  GROUP BY week_index
)

SELECT
  CONCAT('Week ', CAST(w AS STRING)) AS week,
  COALESCE(r.users, 0)              AS user_count         -- Week 0 = new users, Weeks 1‑4 = retained
FROM UNNEST(GENERATE_ARRAY(0, 4)) AS w
LEFT JOIN retention_raw AS r
ON r.week_index = w
ORDER BY w;