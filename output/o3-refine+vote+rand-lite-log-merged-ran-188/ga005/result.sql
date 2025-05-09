/*  Week-2 retention by weekly cohort (Mon-Sun)
    Cohorts: 2018-07-09 … 2018-09-17        */

WITH cohort_candidates AS (     -- brand-new users
  SELECT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS cohort_week_start
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND event_name = 'session_start'
    -- “new” = first session day equals user_first_touch date
    AND event_date = FORMAT_DATE(
                      '%Y%m%d',
                      DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
                    )
),

cohorts AS (                    -- keep only analyzable cohorts
  SELECT DISTINCT
    user_pseudo_id,
    cohort_week_start
  FROM cohort_candidates
  WHERE cohort_week_start BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),

cohort_sizes AS (
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS cohort_users
  FROM cohorts
  GROUP BY cohort_week_start
),

week2_returns AS (              -- users who came back in week-2 (day 14-20)
  SELECT DISTINCT
    c.user_pseudo_id,
    c.cohort_week_start
  FROM cohorts c
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180723' AND '20181002'   -- tables that can hold week-2 events
    AND e.event_name = 'session_start'
    AND PARSE_DATE('%Y%m%d', e.event_date)
        BETWEEN DATE_ADD(c.cohort_week_start, INTERVAL 14 DAY)
            AND DATE_ADD(c.cohort_week_start, INTERVAL 20 DAY)
),

retained_counts AS (
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS week2_users
  FROM week2_returns
  GROUP BY cohort_week_start
)

SELECT
  cs.cohort_week_start AS cohort_week,
  ROUND(
    SAFE_DIVIDE(COALESCE(rc.week2_users, 0), cs.cohort_users) * 100,
    2
  ) AS week2_retention_rate
FROM cohort_sizes cs
LEFT JOIN retained_counts rc
  USING (cohort_week_start)
ORDER BY cohort_week_start;