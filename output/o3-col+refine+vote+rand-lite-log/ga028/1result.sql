-- 7-day (weekly) retention for users whose first session occurred
-- in the week starting Monday 2018-07-02 (Week 0)   
-- Data window: 2018-07-02 … 2018-10-02

WITH first_sessions AS (
  -- Each user’s first session, truncated to the Monday of that week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180601' AND '20181002'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
  HAVING cohort_week = DATE '2018-07-02'          -- Cohort = week of 02-Jul-2018
),

weeks_seen AS (
  -- Distinct Monday-based weeks (0-4) in which each cohort user was active
  SELECT DISTINCT
    fs.user_pseudo_id,
    DATE_DIFF(
      DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
      fs.cohort_week,
      WEEK
    ) AS week_number
  FROM first_sessions AS fs
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = fs.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    AND DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY))
        BETWEEN fs.cohort_week
        AND DATE_ADD(fs.cohort_week, INTERVAL 4 WEEK)
)

SELECT
  COUNTIF(week_number = 0) AS week0_new_users,
  COUNTIF(week_number = 1) AS week1_retained,
  COUNTIF(week_number = 2) AS week2_retained,
  COUNTIF(week_number = 3) AS week3_retained,
  COUNTIF(week_number = 4) AS week4_retained
FROM weeks_seen;