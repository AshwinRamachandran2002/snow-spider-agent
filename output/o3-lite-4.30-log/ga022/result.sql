WITH first_open AS (        -- each user’s very first app‑open
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),
cohort AS (                 -- new users in 1‑Sep‑2018 … 7‑Sep‑2018
  SELECT user_pseudo_id
  FROM first_open
  WHERE first_open_date BETWEEN '20180901' AND '20180907'
),
cohort_size AS (            -- cohort size
  SELECT COUNT(*) AS n FROM cohort
),
week_retention AS (         -- cohort members that returned in each week
  SELECT 1 AS wk, COUNT(DISTINCT e.user_pseudo_id) AS users
  FROM `firebase-public-project.analytics_153293282.events_201809*` e
  JOIN cohort USING (user_pseudo_id)
  WHERE e.event_date BETWEEN '20180908' AND '20180914'
  UNION ALL
  SELECT 2, COUNT(DISTINCT e.user_pseudo_id)
  FROM `firebase-public-project.analytics_153293282.events_201809*` e
  JOIN cohort USING (user_pseudo_id)
  WHERE e.event_date BETWEEN '20180915' AND '20180921'
  UNION ALL
  SELECT 3, COUNT(DISTINCT e.user_pseudo_id)
  FROM `firebase-public-project.analytics_153293282.events_201809*` e
  JOIN cohort USING (user_pseudo_id)
  WHERE e.event_date BETWEEN '20180922' AND '20180928'
),
pivot AS (                  -- place week counts into columns
  SELECT
    MAX(CASE WHEN wk = 1 THEN users END) AS w1_users,
    MAX(CASE WHEN wk = 2 THEN users END) AS w2_users,
    MAX(CASE WHEN wk = 3 THEN users END) AS w3_users
  FROM week_retention
)
SELECT
  '2018-09-01'                                       AS cohort_start_week,
  ROUND(w1_users / n, 4)                             AS week1_retention_rate,
  ROUND(w2_users / n, 4)                             AS week2_retention_rate,
  ROUND(w3_users / n, 4)                             AS week3_retention_rate
FROM pivot
CROSS JOIN cohort_size;