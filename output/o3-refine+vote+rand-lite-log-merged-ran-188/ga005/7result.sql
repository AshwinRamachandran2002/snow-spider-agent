-- Weekly cohort analysis (Week-2 retention) for GA4 demo data
WITH base AS (  -- all session_start events within analysis window
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)                                           AS event_dt,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY))                 AS event_week,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))                         AS first_touch_dt,
    DATE_TRUNC(DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)), WEEK(MONDAY)) AS cohort_week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'      -- tables in scope
    AND event_name = 'session_start'
),
cohort_users AS (  -- week-0 users (new users)
  SELECT DISTINCT
    user_pseudo_id,
    cohort_week
  FROM base
  WHERE event_dt = first_touch_dt           -- first session occurs on first-touch day
),
activity AS (      -- all later activity for those cohort users
  SELECT
    b.user_pseudo_id,
    c.cohort_week,
    DATE_DIFF(b.event_week, c.cohort_week, WEEK(MONDAY)) AS weeks_since
  FROM base b
  JOIN cohort_users c
  USING (user_pseudo_id)
)
SELECT
  cohort_week                           AS cohort_start_monday,
  COUNTIF(weeks_since = 0)              AS cohort_user_cnt,
  COUNTIF(weeks_since = 2)              AS week2_returning_user_cnt,
  ROUND(
    SAFE_DIVIDE(COUNTIF(weeks_since = 2), COUNTIF(weeks_since = 0)) * 100,
    2
  )                                     AS week2_retention_pct
FROM activity
WHERE cohort_week BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'  -- cohorts that allow full 2-week lookback
GROUP BY cohort_week
ORDER BY cohort_week;