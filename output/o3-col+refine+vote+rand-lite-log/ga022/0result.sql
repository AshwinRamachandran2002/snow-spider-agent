WITH
-- 0) Cohort = users whose very first `first_open` happened during Sep-01 – Sep-07 2018 (Asia/Shanghai)
cohort AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'
    AND event_name = 'first_open'
    AND DATE(TIMESTAMP_MICROS(event_timestamp),'Asia/Shanghai')
        BETWEEN '2018-09-01' AND '2018-09-07'
),

-- 1) Users who came back in Week-1 (Sep-08 – Sep-14)
week1 AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180908' AND '20180914'
    AND DATE(TIMESTAMP_MICROS(event_timestamp),'Asia/Shanghai')
        BETWEEN '2018-09-08' AND '2018-09-14'
),

-- 2) Users who came back in Week-2 (Sep-15 – Sep-21)
week2 AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180915' AND '20180921'
    AND DATE(TIMESTAMP_MICROS(event_timestamp),'Asia/Shanghai')
        BETWEEN '2018-09-15' AND '2018-09-21'
),

-- 3) Users who came back in Week-3 (Sep-22 – Sep-28)
week3 AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180922' AND '20180928'
    AND DATE(TIMESTAMP_MICROS(event_timestamp),'Asia/Shanghai')
        BETWEEN '2018-09-22' AND '2018-09-28'
)

-- 4) Final weekly retention rates (percentages rounded to 4 decimals)
SELECT
  COUNT(*)                                                                        AS cohort_size ,
  ROUND(COUNTIF(user_pseudo_id IN (SELECT * FROM week1))*100.0 / COUNT(*), 4)    AS retention_week1_pct ,
  ROUND(COUNTIF(user_pseudo_id IN (SELECT * FROM week2))*100.0 / COUNT(*), 4)    AS retention_week2_pct ,
  ROUND(COUNTIF(user_pseudo_id IN (SELECT * FROM week3))*100.0 / COUNT(*), 4)    AS retention_week3_pct
FROM cohort;