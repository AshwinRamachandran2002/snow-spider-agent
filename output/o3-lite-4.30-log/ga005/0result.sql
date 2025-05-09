WITH base AS (   -- all session_start events in the usable range
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)                   AS event_dt,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)) AS first_touch_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
),

cohort_users AS (   -- users whose very first session falls in the cohort week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_touch_dt, WEEK(MONDAY)) AS cohort_week_start
  FROM base
  WHERE event_dt = first_touch_dt
    AND DATE_TRUNC(first_touch_dt, WEEK(MONDAY))
        BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),

week2_activity AS (   -- those users seen again during Week 2 (days 14‑20)
  SELECT DISTINCT
    cu.user_pseudo_id,
    cu.cohort_week_start
  FROM cohort_users cu
  JOIN base b
    ON b.user_pseudo_id = cu.user_pseudo_id
   AND b.event_dt BETWEEN cu.cohort_week_start + INTERVAL 14 DAY
                      AND cu.cohort_week_start + INTERVAL 20 DAY
)

SELECT
  cu.cohort_week_start,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT wa.user_pseudo_id),
      COUNT(DISTINCT cu.user_pseudo_id)
    ), 4
  ) AS week2_retention_rate
FROM cohort_users cu
LEFT JOIN week2_activity wa
  ON wa.user_pseudo_id = cu.user_pseudo_id
  AND wa.cohort_week_start = cu.cohort_week_start
GROUP BY cu.cohort_week_start
ORDER BY cu.cohort_week_start;