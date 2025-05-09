/*  Weekly retention for users whose very first `first_open`
    happened between 1‒7 Sep 2018 (Asia/Shanghai, UTC+8)      */

WITH cohort AS (           -- day-0 : first time the user opened the app
  SELECT
    `user_pseudo_id`,
    MIN( TIMESTAMP_MICROS(`event_timestamp` + 28800000000) ) AS day0
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE `event_name` = 'first_open'
  GROUP BY `user_pseudo_id`
  HAVING day0 BETWEEN TIMESTAMP '2018-09-01 00:00:00+08'
                 AND   TIMESTAMP '2018-09-07 23:59:59+08'
),

returns AS (               -- distinct return-days within the first 3 weeks
  SELECT DISTINCT
    e.`user_pseudo_id`,
    DATE_DIFF( DATE(TIMESTAMP_MICROS(e.`event_timestamp` + 28800000000)),
               DATE(c.day0), DAY ) AS diff_days
  FROM `firebase-public-project.analytics_153293282.events_201809*` e
  JOIN cohort c
    ON e.`user_pseudo_id` = c.`user_pseudo_id`
  WHERE DATE_DIFF( DATE(TIMESTAMP_MICROS(e.`event_timestamp` + 28800000000)),
                   DATE(c.day0), DAY ) BETWEEN 1 AND 21
)

SELECT
  COUNT(DISTINCT c.`user_pseudo_id`)                                                       AS cohort_size,
  ROUND( COUNT(DISTINCT IF(diff_days BETWEEN 1  AND 7 , r.`user_pseudo_id`, NULL)) /
         COUNT(DISTINCT c.`user_pseudo_id`), 4)                                            AS week1_retention,
  ROUND( COUNT(DISTINCT IF(diff_days BETWEEN 8  AND 14, r.`user_pseudo_id`, NULL)) /
         COUNT(DISTINCT c.`user_pseudo_id`), 4)                                            AS week2_retention,
  ROUND( COUNT(DISTINCT IF(diff_days BETWEEN 15 AND 21, r.`user_pseudo_id`, NULL)) /
         COUNT(DISTINCT c.`user_pseudo_id`), 4)                                            AS week3_retention
FROM cohort c
LEFT JOIN returns r
  ON c.`user_pseudo_id` = r.`user_pseudo_id`;