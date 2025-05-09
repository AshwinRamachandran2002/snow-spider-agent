WITH base AS (
  -- every session_start in the window we need
  SELECT
    user_pseudo_id,
    DATE_TRUNC(DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)), WEEK(MONDAY)) AS cohort_week_start,
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS ev_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
),

new_users AS (
  -- users whose very first session happens in their cohort week (day-0)
  SELECT DISTINCT
    user_pseudo_id,
    cohort_week_start
  FROM base
  WHERE ev_date = cohort_week_start
    AND cohort_week_start BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),

week2_retained AS (
  -- those same users having another session_start in week 2 (days 14-20)
  SELECT DISTINCT
    b.user_pseudo_id,
    n.cohort_week_start
  FROM new_users n
  JOIN base b
    ON b.user_pseudo_id = n.user_pseudo_id
   AND b.ev_date BETWEEN DATE_ADD(n.cohort_week_start, INTERVAL 14 DAY)
                     AND DATE_ADD(n.cohort_week_start, INTERVAL 20 DAY)
)

SELECT
  cohort_week_start                                         AS cohort_date,
  ROUND(
    SAFE_DIVIDE(COUNT(DISTINCT week2_retained.user_pseudo_id),
                COUNT(DISTINCT new_users.user_pseudo_id))
  , 4)                                                      AS week2_retention_rate
FROM new_users
LEFT JOIN week2_retained
  USING (user_pseudo_id, cohort_week_start)
GROUP BY cohort_week_start
ORDER BY cohort_week_start;