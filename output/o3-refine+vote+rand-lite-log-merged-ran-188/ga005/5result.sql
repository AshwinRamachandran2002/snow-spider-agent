/*  Week-2 retention for weekly cohorts (Mon-start) – GA4 public gaming dataset  */

WITH cohorts AS (                      -- users whose FIRST session is in the cohort week
  SELECT
    DATE_TRUNC(DATE(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_week,
    user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20180917'              -- cohort weeks
    AND event_name = 'session_start'
    AND DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
        = DATE(PARSE_DATE('%Y%m%d', event_date))                     -- “new” users
),

week2_events AS (                     -- session_start events that can satisfy week-2 return
  SELECT
    DATE_TRUNC(DATE(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS event_week,
    user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180723' AND '20181002'              -- two-week window
    AND event_name = 'session_start'
)

SELECT
  cohort_week,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE
                       WHEN w.user_pseudo_id IS NOT NULL THEN c.user_pseudo_id
                     END),
      COUNT(DISTINCT c.user_pseudo_id)
    ), 4)                                         AS week2_retention_rate
FROM cohorts c
LEFT JOIN week2_events w
  ON w.user_pseudo_id = c.user_pseudo_id
  AND w.event_week = DATE_ADD(c.cohort_week, INTERVAL 2 WEEK)        -- exactly 2 weeks later
GROUP BY cohort_week
HAVING cohort_week BETWEEN '2018-07-09' AND '2018-09-17'             -- only cohorts we can rate
ORDER BY cohort_week;