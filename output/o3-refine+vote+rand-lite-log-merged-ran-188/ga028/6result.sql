-- 7‑day retention (Week‑0 … Week‑4) for the cohort whose first‑ever
-- session_start happened in the Monday‑based week that begins 2018‑07‑02.
-- All events considered are on or before 2018‑10‑02.

WITH all_session_starts AS (
  /* every session_start up to 2‑Oct‑2018 */
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX <= '20181002'
),

first_session AS (
  /* the very first session_start we have for each user */
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM all_session_starts
  GROUP BY user_pseudo_id
),

cohort AS (
  /* keep only users whose first session fell in the week 2‑Jul‑2018 … 8‑Jul‑2018 */
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week_start        -- = 2018‑07‑02
  FROM first_session
  WHERE first_session_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),

weekly_visits AS (
  /* each subsequent weekly visit for those cohort users, up to Week‑4 */
  SELECT
    a.user_pseudo_id,
    DATE_DIFF(
      DATE_TRUNC(a.event_date, WEEK(MONDAY)),       -- week the visit happened
      c.cohort_week_start,                          -- cohort’s week (2018‑07‑02)
      WEEK(MONDAY)
    ) AS week_number
  FROM all_session_starts a
  JOIN cohort              c ON c.user_pseudo_id = a.user_pseudo_id
  WHERE a.event_date <= DATE '2018-10-02'
    AND DATE_DIFF(
          DATE_TRUNC(a.event_date, WEEK(MONDAY)),
          c.cohort_week_start,
          WEEK(MONDAY)
        ) BETWEEN 0 AND 4                            -- keep only Week‑0 … Week‑4
),

retention AS (
  /* one row per (week_number), deduplicated at user level */
  SELECT
    week_number,
    COUNT(DISTINCT user_pseudo_id) AS users
  FROM (
    SELECT DISTINCT user_pseudo_id, week_number
    FROM weekly_visits
  )
  GROUP BY week_number
)

/* pivot so that Week‑0 is “new users”, Weeks 1‑4 are “retained” */
SELECT
  MAX(CASE WHEN week_number = 0 THEN users END) AS week0_new_users,
  MAX(CASE WHEN week_number = 1 THEN users END) AS week1_retained,
  MAX(CASE WHEN week_number = 2 THEN users END) AS week2_retained,
  MAX(CASE WHEN week_number = 3 THEN users END) AS week3_retained,
  MAX(CASE WHEN week_number = 4 THEN users END) AS week4_retained
FROM retention;