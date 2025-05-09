-- Weekly retention (weeks 1‑3) for users whose first_open happened
-- between 1 Sep 2018 and 7 Sep 2018, calendar converted to Asia/Shanghai

WITH cohort AS (           -- users who first opened in the first week of Sept
  SELECT
    user_pseudo_id,
    MIN(TIMESTAMP_MICROS(event_timestamp))           AS first_open_ts_utc
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
    AND _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'   -- tables 1–7 Sep 2018
  GROUP BY user_pseudo_id
),
cohort_sh AS (             -- same cohort, but in Shanghai date
  SELECT
    user_pseudo_id,
    DATE(first_open_ts_utc , 'Asia/Shanghai')        AS first_open_date_sh
  FROM cohort
),
events_in_september AS (   -- all events the cohort generated in September 2018
  SELECT
    e.user_pseudo_id,
    DATE(TIMESTAMP_MICROS(e.event_timestamp), 'Asia/Shanghai') AS event_date_sh,
    c.first_open_date_sh
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN cohort_sh c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'       -- entire September
),
user_week_flags AS (       -- whether each user was active in weeks 1,2,3
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN DATE_DIFF(event_date_sh, first_open_date_sh, DAY) BETWEEN  1 AND  7 THEN 1 ELSE 0 END) AS week1_flag,
    MAX(CASE WHEN DATE_DIFF(event_date_sh, first_open_date_sh, DAY) BETWEEN  8 AND 14 THEN 1 ELSE 0 END) AS week2_flag,
    MAX(CASE WHEN DATE_DIFF(event_date_sh, first_open_date_sh, DAY) BETWEEN 15 AND 21 THEN 1 ELSE 0 END) AS week3_flag
  FROM events_in_september
  GROUP BY user_pseudo_id
)

SELECT
  ROUND(SUM(week1_flag) / COUNT(*), 4) AS week1_retention,
  ROUND(SUM(week2_flag) / COUNT(*), 4) AS week2_retention,
  ROUND(SUM(week3_flag) / COUNT(*), 4) AS week3_retention
FROM user_week_flags;