/* Week‑2 retention for Monday‑based cohorts
   Cohorts analysed: 09‑Jul‑2018 … 17‑Sep‑2018             */
WITH sessions AS (
  SELECT
      user_pseudo_id,
      event_date,
      DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS activity_week,
      DATE_TRUNC(
          PARSE_DATE('%Y%m%d',
                     FORMAT_TIMESTAMP('%Y%m%d', TIMESTAMP_MICROS(user_first_touch_timestamp))
                    ),
          WEEK(MONDAY)
      ) AS first_touch_week,
      FORMAT_TIMESTAMP('%Y%m%d', TIMESTAMP_MICROS(user_first_touch_timestamp)) AS first_touch_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
),
cohorts AS (                       -- users whose first session is in the cohort week
  SELECT DISTINCT
         user_pseudo_id,
         first_touch_week AS cohort_week
  FROM sessions
  WHERE event_date = first_touch_date
    AND first_touch_week BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),
week_activity AS (                 -- weeks in which each user was active
  SELECT DISTINCT
         user_pseudo_id,
         activity_week
  FROM sessions
)
SELECT
    cohort_week                                   AS cohort_week_start,
    ROUND(
      100 *
      COUNT(DISTINCT IF(activity_week = cohort_week + INTERVAL 2 WEEK,
                         user_pseudo_id,
                         NULL))
      / COUNT(DISTINCT cohorts.user_pseudo_id)
    , 4)                                          AS week2_retention_rate
FROM cohorts
LEFT JOIN week_activity USING (user_pseudo_id)
GROUP BY cohort_week
ORDER BY cohort_week;