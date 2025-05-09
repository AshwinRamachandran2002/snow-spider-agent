-- Weekly cohort ↔︎ week-2 retention (Mon-based weeks)
WITH base AS (
  -- all session_start events in the period of interest
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)                        AS event_dt,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))      AS first_touch_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
),

cohorts AS (
  -- new-user cohort = first session_start falls on first-touch date
  SELECT
    DATE_TRUNC(event_dt, WEEK(MONDAY)) AS cohort_week,
    user_pseudo_id
  FROM base
  WHERE event_dt = first_touch_dt
),

week2_retained AS (
  -- users who fired a session_start in the (14-20]-day window
  SELECT DISTINCT
    c.cohort_week,
    c.user_pseudo_id
  FROM cohorts AS c
  JOIN base     AS b
    ON b.user_pseudo_id = c.user_pseudo_id
  WHERE b.event_dt BETWEEN DATE_ADD(c.cohort_week, INTERVAL 14 DAY)
                       AND DATE_ADD(c.cohort_week, INTERVAL 20 DAY)
)

SELECT
  c.cohort_week,
  ROUND(100 * COUNT(DISTINCT w.user_pseudo_id)
              / COUNT(DISTINCT c.user_pseudo_id), 2) AS week2_retention_pct
FROM cohorts AS c
LEFT JOIN week2_retained AS w
  ON w.cohort_week = c.cohort_week
 AND w.user_pseudo_id = c.user_pseudo_id
GROUP BY c.cohort_week
HAVING c.cohort_week BETWEEN '2018-07-09' AND '2018-09-17'
ORDER BY c.cohort_week;