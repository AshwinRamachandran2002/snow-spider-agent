WITH sessions AS (
  -- every session_start that will be needed
  SELECT
    user_pseudo_id,
    DATE(PARSE_DATE('%Y%m%d', event_date))       AS event_day,
    TIMESTAMP_MICROS(user_first_touch_timestamp) AS first_touch_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
),
cohorts AS (
  -- users whose FIRST session occurs inside the analysis window,
  -- bucketed into the Monday that starts their first-session week
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(event_day, WEEK(MONDAY))          AS cohort_monday
  FROM sessions
  WHERE event_day = DATE(first_touch_ts)         -- “new” users
    AND DATE_TRUNC(event_day, WEEK(MONDAY))
        BETWEEN '2018-07-09' AND '2018-09-17'    -- cohorts we can evaluate
),
week2_sessions AS (
  -- all cohort users who return during their “week-2”
  SELECT DISTINCT
    s.user_pseudo_id,
    c.cohort_monday
  FROM sessions AS s
  JOIN cohorts  AS c
    ON s.user_pseudo_id = c.user_pseudo_id
  WHERE s.event_day BETWEEN DATE_ADD(c.cohort_monday, INTERVAL 14 DAY)
                       AND DATE_ADD(c.cohort_monday, INTERVAL 20 DAY)
)
SELECT
  c.cohort_monday AS cohort_monday,
  ROUND(
    100 * SAFE_DIVIDE(
            COUNT(DISTINCT w.user_pseudo_id),
            COUNT(DISTINCT c.user_pseudo_id)
       ), 4
  ) AS week2_retention_pct
FROM cohorts AS c
LEFT JOIN week2_sessions AS w
       ON c.user_pseudo_id = w.user_pseudo_id
GROUP BY c.cohort_monday
ORDER BY c.cohort_monday;