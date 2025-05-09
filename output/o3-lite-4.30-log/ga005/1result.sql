WITH new_users AS (        -- users whose first session is in the cohort week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS cohort_week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
    AND event_date = FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)))
    AND PARSE_DATE('%Y%m%d', event_date) BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),
cohort_sizes AS (
  SELECT
    cohort_week,
    COUNT(DISTINCT user_pseudo_id) AS cohort_users
  FROM new_users
  GROUP BY cohort_week
),
week2_returners AS (
  SELECT DISTINCT
    n.cohort_week,
    e.user_pseudo_id
  FROM new_users n
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = n.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180723' AND '20181002'
    AND e.event_name = 'session_start'
    AND DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), n.cohort_week, DAY) BETWEEN 14 AND 20
)
SELECT
  c.cohort_week AS cohort_week_start,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT w.user_pseudo_id), c.cohort_users), 4) AS week2_retention_rate
FROM cohort_sizes c
LEFT JOIN week2_returners w
  ON w.cohort_week = c.cohort_week
GROUP BY c.cohort_week, c.cohort_users
ORDER BY c.cohort_week;