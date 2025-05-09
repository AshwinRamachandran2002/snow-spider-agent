/*  Weekly retention for the cohort whose very first `first_open`
    happened in Shanghai time between 1 Sep 2018 and 7 Sep 2018       */

WITH events AS (           -- bring only the days we need
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai') AS event_date_sh
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180831' AND '20180928'      -- spans 1‑Sep to 28‑Sep (UTC+8)
),

/* cohort = users whose first *ever* first_open falls inside 1‑7 Sep 2018 (Shanghai) */
cohort AS (
  SELECT
    user_pseudo_id,
    MIN(event_date_sh) AS first_open_date
  FROM events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
  HAVING first_open_date BETWEEN '2018-09-01' AND '2018-09-07'
),

cohort_size AS (
  SELECT COUNT(*) AS cohort_users FROM cohort
),

/* find on which week (1,2,3) each cohort user returned */
retention_raw AS (
  SELECT DISTINCT
    e.user_pseudo_id,
    CASE
      WHEN DATE_DIFF(e.event_date_sh, c.first_open_date, DAY) BETWEEN  1 AND  7 THEN 1   -- week 1
      WHEN DATE_DIFF(e.event_date_sh, c.first_open_date, DAY) BETWEEN  8 AND 14 THEN 2   -- week 2
      WHEN DATE_DIFF(e.event_date_sh, c.first_open_date, DAY) BETWEEN 15 AND 21 THEN 3   -- week 3
    END AS retention_week
  FROM events  AS e
  JOIN cohort  AS c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE DATE_DIFF(e.event_date_sh, c.first_open_date, DAY) BETWEEN 1 AND 21   -- look only after day 0
),

retention_counts AS (
  SELECT
    retention_week,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM retention_raw
  WHERE retention_week IS NOT NULL
  GROUP BY retention_week
)

/* final pivoted result */
SELECT
  cs.cohort_users,
  ROUND(IFNULL(w1.retained_users, 0) / cs.cohort_users * 100, 4) AS week1_retention_rate,
  ROUND(IFNULL(w2.retained_users, 0) / cs.cohort_users * 100, 4) AS week2_retention_rate,
  ROUND(IFNULL(w3.retained_users, 0) / cs.cohort_users * 100, 4) AS week3_retention_rate
FROM cohort_size AS cs
LEFT JOIN retention_counts AS w1 ON w1.retention_week = 1
LEFT JOIN retention_counts AS w2 ON w2.retention_week = 2
LEFT JOIN retention_counts AS w3 ON w3.retention_week = 3;