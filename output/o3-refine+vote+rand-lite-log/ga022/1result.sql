/*  Weekly retention of the cohort that installed (first_open) between
    1 Sep 2018 00:00 and 7 Sep 2018 23:59 (Asia/Shanghai)

    week1 = return on day 1‑7 after first_open
    week2 = return on day 8‑14 after first_open
    week3 = return on day 15‑21 after first_open
*/

WITH events AS (
  SELECT
      user_pseudo_id,
      event_name,
      -- convert GA4 micro‑seconds UTC to Asia/Shanghai time
      TIMESTAMP_MICROS(event_timestamp) + INTERVAL 8 HOUR AS event_ts_sh
  FROM `firebase-public-project.analytics_153293282.events_*`
  -- need data from 1 Sep through 28 Sep 2018 for the whole 3‑week window
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180928'
),

/* users whose very first first_open happened in the cohort week */
cohort AS (
  SELECT
      user_pseudo_id,
      MIN(event_ts_sh) AS first_open_ts
  FROM events
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),

cohort_users AS (
  SELECT
      user_pseudo_id,
      first_open_ts
  FROM cohort
  WHERE DATE(first_open_ts) BETWEEN '2018-09-01' AND '2018-09-07'   -- Asia/Shanghai dates
),

/* all events of those users within 21 days after first_open                */
returns AS (
  SELECT
      e.user_pseudo_id,
      DATE_DIFF(DATE(e.event_ts_sh), DATE(cu.first_open_ts), DAY) AS days_since_first
  FROM events AS e
  JOIN cohort_users AS cu
    USING (user_pseudo_id)
  -- disregard the install day itself, keep only day 1‑21
  WHERE DATE_DIFF(DATE(e.event_ts_sh), DATE(cu.first_open_ts), DAY) BETWEEN 1 AND 21
),

/* flag whether each user returned in each 7‑day bucket                     */
flags AS (
  SELECT
      cu.user_pseudo_id,
      MAX(CASE WHEN r.days_since_first BETWEEN  1 AND  7 THEN 1 ELSE 0 END) AS week1,
      MAX(CASE WHEN r.days_since_first BETWEEN  8 AND 14 THEN 1 ELSE 0 END) AS week2,
      MAX(CASE WHEN r.days_since_first BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS week3
  FROM cohort_users           AS cu
  LEFT JOIN returns AS r
    ON cu.user_pseudo_id = r.user_pseudo_id
  GROUP BY cu.user_pseudo_id
)

/* ------------------------------------------------------------------------ */
SELECT
    COUNT(*)                                                   AS cohort_size,
    ROUND(SAFE_DIVIDE(SUM(week1), COUNT(*)), 4) AS week1_retention_rate,
    ROUND(SAFE_DIVIDE(SUM(week2), COUNT(*)), 4) AS week2_retention_rate,
    ROUND(SAFE_DIVIDE(SUM(week3), COUNT(*)), 4) AS week3_retention_rate
FROM flags;