-- Weekly retention (W1 / W2 / W3) for users whose very first
-- “first_open” happened during 1–7 Sep 2018 (Asia/Shanghai)

WITH
/* 1️⃣  Cohort : users whose *first_open* fell inside the first
        calendar‑week of September 2018 in Asia/Shanghai time      */
cohort AS (
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(event_timestamp)           AS first_open_ts_utc
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'
    AND event_name = 'first_open'
    AND DATE(TIMESTAMP_MICROS(event_timestamp),'Asia/Shanghai')
        BETWEEN '2018-09-01' AND '2018-09-07'
),

/* 2️⃣  All events we will look at (through 3 Oct 2018 so that
        week‑3 activity is covered)                                 */
all_events AS (
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(event_timestamp) AS evt_ts_utc
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181003'
),

/* 3️⃣  For every cohort member, find the 7‑day bucket (1,2,3)
        in which he/she returned                                     */
user_week_return AS (
  SELECT DISTINCT
    c.user_pseudo_id,
    FLOOR(
      DATE_DIFF(
        DATE(evt_ts_utc,     'Asia/Shanghai'),
        DATE(first_open_ts_utc,'Asia/Shanghai'),
        DAY
      ) / 7
    ) + 1 AS week_idx             -- 1 = week‑1, 2 = week‑2, 3 = week‑3
  FROM cohort            AS c
  JOIN all_events        AS e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE DATE_DIFF(
          DATE(evt_ts_utc, 'Asia/Shanghai'),
          DATE(first_open_ts_utc,'Asia/Shanghai'),
          DAY
        ) BETWEEN 1 AND 21        -- keep only weeks 1‑3
),

/* 4️⃣  Count unique users per week and cohort size                  */
counts AS (
  SELECT
    (SELECT COUNT(*) FROM cohort)                               AS cohort_size,
    (SELECT COUNT(DISTINCT user_pseudo_id)
       FROM user_week_return WHERE week_idx = 1)               AS w1_users,
    (SELECT COUNT(DISTINCT user_pseudo_id)
       FROM user_week_return WHERE week_idx = 2)               AS w2_users,
    (SELECT COUNT(DISTINCT user_pseudo_id)
       FROM user_week_return WHERE week_idx = 3)               AS w3_users
)

/* 5️⃣  Final retention rates                                       */
SELECT
  ROUND(w1_users / cohort_size, 4) AS week1_retention,
  ROUND(w2_users / cohort_size, 4) AS week2_retention,
  ROUND(w3_users / cohort_size, 4) AS week3_retention
FROM counts;