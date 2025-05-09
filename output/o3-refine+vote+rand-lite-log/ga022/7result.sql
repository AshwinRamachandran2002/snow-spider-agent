/*  Weekly retention for users whose very first “first_open”
    occurred 2018‑09‑01 to 2018‑09‑07 (Asia/Shanghai).
    Outputs retention for weeks 1, 2 and 3 following that period. */

WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai') AS event_date_sh
  FROM `firebase-public-project.analytics_153293282.events_201809*`
),

-- Cohort: users whose first ever first_open is in 1‑Sep‑2018 … 7‑Sep‑2018
cohort AS (
  SELECT
    user_pseudo_id
  FROM events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
  HAVING MIN(event_date_sh) BETWEEN '2018-09-01' AND '2018-09-07'
),

-- Activity of cohort users in weeks 1, 2, 3 after cohort week
retention_flags AS (
  SELECT DISTINCT
    c.user_pseudo_id,
    CASE
      WHEN e.event_date_sh BETWEEN '2018-09-08' AND '2018-09-14' THEN 1
      WHEN e.event_date_sh BETWEEN '2018-09-15' AND '2018-09-21' THEN 2
      WHEN e.event_date_sh BETWEEN '2018-09-22' AND '2018-09-28' THEN 3
    END AS retention_week
  FROM cohort AS c
  JOIN events AS e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e.event_date_sh BETWEEN '2018-09-08' AND '2018-09-28'
),

-- Count distinct cohort users active in each week
retention_counts AS (
  SELECT
    retention_week,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM retention_flags
  GROUP BY retention_week
),

-- Size of the cohort
cohort_size AS (
  SELECT COUNT(*) AS cohort_users FROM cohort
)

-- Final retention rates (4‑decimal precision)
SELECT
  ROUND(
    SAFE_DIVIDE(
      MAX(CASE WHEN retention_week = 1 THEN retained_users END),
      ANY_VALUE(cohort_users)
    ), 4) AS week_1_retention,
  ROUND(
    SAFE_DIVIDE(
      MAX(CASE WHEN retention_week = 2 THEN retained_users END),
      ANY_VALUE(cohort_users)
    ), 4) AS week_2_retention,
  ROUND(
    SAFE_DIVIDE(
      MAX(CASE WHEN retention_week = 3 THEN retained_users END),
      ANY_VALUE(cohort_users)
    ), 4) AS week_3_retention
FROM retention_counts
CROSS JOIN cohort_size;