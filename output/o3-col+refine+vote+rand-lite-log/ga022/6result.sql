/*  Weekly retention (W1, W2, W3) for users whose very first `first_open`
    happened during 01-07 Sep 2018 (Asia/Shanghai)                       */
WITH cohort AS (      -- users whose FIRST “first_open” is in 01-07 Sep
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'
    AND event_name = 'first_open'
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')
        BETWEEN '2018-09-01' AND '2018-09-07'
),
week1 AS (            -- activity in 08-14 Sep
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180908' AND '20180914'
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')
        BETWEEN '2018-09-08' AND '2018-09-14'
),
week2 AS (            -- activity in 15-21 Sep
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180915' AND '20180921'
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')
        BETWEEN '2018-09-15' AND '2018-09-21'
),
week3 AS (            -- activity in 22-28 Sep
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180922' AND '20180928'
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')
        BETWEEN '2018-09-22' AND '2018-09-28'
)

SELECT
  COUNT(*)                                   AS cohort_users,
  COUNT(DISTINCT w1.user_pseudo_id)          AS week1_users,
  COUNT(DISTINCT w2.user_pseudo_id)          AS week2_users,
  COUNT(DISTINCT w3.user_pseudo_id)          AS week3_users,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT w1.user_pseudo_id), COUNT(*)), 4)
                                             AS week1_retention_rate,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT w2.user_pseudo_id), COUNT(*)), 4)
                                             AS week2_retention_rate,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT w3.user_pseudo_id), COUNT(*)), 4)
                                             AS week3_retention_rate
FROM cohort c
LEFT JOIN week1 w1 USING (user_pseudo_id)
LEFT JOIN week2 w2 USING (user_pseudo_id)
LEFT JOIN week3 w3 USING (user_pseudo_id);