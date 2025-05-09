-- Weekly retention (Shanghai time) for users whose very first
-- “first_open” happened during 1–7 Sep 2018

WITH
/* --- 1)  Week-0 cohort --------------------------------------------------- */
cohort AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'        -- read only 1-7 Sep tables
    AND event_name = 'first_open'
    -- convert the micro-second timestamp to Shanghai date
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')
        BETWEEN '2018-09-01' AND '2018-09-07'
),

/* --- 2)  Flag every cohort user that comes back in each follow-up week --- */
flags AS (
  SELECT
    e.user_pseudo_id,

    MAX(
      IF(
        DATE(TIMESTAMP_MICROS(e.event_timestamp), 'Asia/Shanghai')
           BETWEEN '2018-09-08' AND '2018-09-14',
        1, 0)
    ) AS week1_flag,

    MAX(
      IF(
        DATE(TIMESTAMP_MICROS(e.event_timestamp), 'Asia/Shanghai')
           BETWEEN '2018-09-15' AND '2018-09-21',
        1, 0)
    ) AS week2_flag,

    MAX(
      IF(
        DATE(TIMESTAMP_MICROS(e.event_timestamp), 'Asia/Shanghai')
           BETWEEN '2018-09-22' AND '2018-09-28',
        1, 0)
    ) AS week3_flag

  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN cohort USING (user_pseudo_id)                          -- only cohort users
  WHERE e._TABLE_SUFFIX BETWEEN '20180901' AND '20180928'     -- scan Week-0 through Week-3
  GROUP BY e.user_pseudo_id
),

/* --- 3)  Aggregate counts & compute retention rates ---------------------- */
retention AS (
  SELECT
    (SELECT COUNT(*) FROM cohort) AS cohort_users,
    SUM(week1_flag)               AS week1_retained,
    SUM(week2_flag)               AS week2_retained,
    SUM(week3_flag)               AS week3_retained
  FROM flags
)

SELECT
  cohort_users,
  week1_retained,
  ROUND(week1_retained / cohort_users, 4) AS week1_retention_rate,
  week2_retained,
  ROUND(week2_retained / cohort_users, 4) AS week2_retention_rate,
  week3_retained,
  ROUND(week3_retained / cohort_users, 4) AS week3_retention_rate
FROM retention;