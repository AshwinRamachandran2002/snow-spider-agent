/*  Weekly retention for the 1–7 Sep 2018 (Shanghai time) “first_open” cohort  */
WITH cohort AS (                                                -- step-1: build cohort
  SELECT user_pseudo_id
  FROM (
    SELECT
      user_pseudo_id,
      MIN(DATE(TIMESTAMP_MICROS(event_timestamp) + INTERVAL 8 HOUR))
        AS first_open_cn                                           -- local (UTC+8) date
    FROM `firebase-public-project.analytics_153293282.events_201809*`
    WHERE event_name = 'first_open'
    GROUP BY user_pseudo_id
  )
  WHERE first_open_cn BETWEEN '2018-09-01' AND '2018-09-07'
),
flags AS (                                                     -- step-2: mark returns
  SELECT
    c.user_pseudo_id,
    MAX(CASE WHEN _TABLE_SUFFIX BETWEEN '20180908' AND '20180914' THEN 1 ELSE 0 END) > 0 AS wk1,
    MAX(CASE WHEN _TABLE_SUFFIX BETWEEN '20180915' AND '20180921' THEN 1 ELSE 0 END) > 0 AS wk2,
    MAX(CASE WHEN _TABLE_SUFFIX BETWEEN '20180922' AND '20180928' THEN 1 ELSE 0 END) > 0 AS wk3
  FROM cohort AS c
  LEFT JOIN `firebase-public-project.analytics_153293282.events_201809*` AS e
         ON e.user_pseudo_id = c.user_pseudo_id
  GROUP BY c.user_pseudo_id
)
SELECT                                                         -- step-3: aggregate
  COUNT(*)                                                     AS cohort_size,
  ROUND(COUNTIF(wk1) / COUNT(*) * 100, 4)                      AS week1_retention_pct,
  ROUND(COUNTIF(wk2) / COUNT(*) * 100, 4)                      AS week2_retention_pct,
  ROUND(COUNTIF(wk3) / COUNT(*) * 100, 4)                      AS week3_retention_pct
FROM flags;