/*  Weekly retention of users whose very first `first_open`
    (in Asia/Shanghai time) happened between 1-Sep and 7-Sep 2018  */

WITH cohort AS (              -- each user's first `first_open`
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_ts_micro_utc
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180831' AND '20180907'            -- UTC span covering 1-7 Sep CN
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
cohort_filtered AS (          -- keep only 1-7 Sep (Asia/Shanghai) first_opens
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(first_ts_micro_utc)                         AS first_ts_utc,
    DATE(TIMESTAMP_MICROS(first_ts_micro_utc), "Asia/Shanghai")  AS first_date_local
  FROM cohort
  WHERE DATE(TIMESTAMP_MICROS(first_ts_micro_utc), "Asia/Shanghai")
        BETWEEN '2018-09-01' AND '2018-09-07'
),
events_after AS (             -- later events in September by cohort users
  SELECT
    e.user_pseudo_id,
    TIMESTAMP_MICROS(e.event_timestamp) AS evt_ts_utc
  FROM `firebase-public-project.analytics_153293282.events_*` e
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
    AND e.user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_filtered)
),
weekly_retention AS (         -- active cohort users in week 1 / 2 / 3
  SELECT
    DATE_DIFF(
      DATE(evt_ts_utc, "Asia/Shanghai"),
      c.first_date_local,
      WEEK(MONDAY)
    )                        AS week_index,
    COUNT(DISTINCT e.user_pseudo_id) AS active_users
  FROM events_after e
  JOIN cohort_filtered c USING (user_pseudo_id)
  GROUP BY week_index
  HAVING week_index BETWEEN 1 AND 3
),
base AS (SELECT COUNT(*) AS cohort_size FROM cohort_filtered)

SELECT
  ROUND(SAFE_DIVIDE(SUM(CASE WHEN week_index = 1 THEN active_users END), MAX(cohort_size)), 4) AS week_1_retention_rate,
  ROUND(SAFE_DIVIDE(SUM(CASE WHEN week_index = 2 THEN active_users END), MAX(cohort_size)), 4) AS week_2_retention_rate,
  ROUND(SAFE_DIVIDE(SUM(CASE WHEN week_index = 3 THEN active_users END), MAX(cohort_size)), 4) AS week_3_retention_rate
FROM weekly_retention
CROSS JOIN base;