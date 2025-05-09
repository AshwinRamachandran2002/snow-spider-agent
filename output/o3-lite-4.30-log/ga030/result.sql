WITH session_events AS (
  SELECT
    user_pseudo_id,
    event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX >= '20180702'
    AND event_name = 'session_start'
),

first_touch AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', MIN(event_date)), WEEK(MONDAY)) AS cohort_week
  FROM session_events
  GROUP BY user_pseudo_id
),

week4_return AS (
  SELECT DISTINCT
    e.user_pseudo_id
  FROM session_events e
  JOIN first_touch f USING (user_pseudo_id)
  WHERE DATE_DIFF(
          DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
          f.cohort_week,
          WEEK(MONDAY)
        ) = 3
),

retention AS (
  SELECT
    f.cohort_week,
    COUNT(*)                      AS cohort_size,
    COUNT(w.user_pseudo_id)       AS week4_retained,
    SAFE_DIVIDE(COUNT(w.user_pseudo_id), COUNT(*)) AS week4_rate
  FROM first_touch f
  LEFT JOIN week4_return w USING (user_pseudo_id)
  GROUP BY cohort_week
)

SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_week) AS cohort_start_date
FROM retention
ORDER BY week4_rate DESC, cohort_week
LIMIT 1;