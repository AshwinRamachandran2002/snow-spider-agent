/*  Week‑2 cohort–retention for the GA4 public‑game dataset
    – Cohorts:   Mondays from 2018‑07‑09 through 2018‑09‑17
    – New user:  first session_start whose event_date = user_first_touch_timestamp
    – Retained:  user fires session_start in the week that is EXACTLY
                 two weeks after the cohort week (week_diff = 2)            */

WITH cohort_users AS (           -- every new user and the Monday of the week they first appeared
  SELECT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS cohort_week_start
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'              -- scan only needed tables
    AND event_name = 'session_start'
    -- “new” user definition
    AND event_date = FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)))
    -- keep only cohorts we are asked for
    AND DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY))
        BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
  GROUP BY user_pseudo_id, cohort_week_start
),

cohort_sizes AS (               -- number of users in each cohort
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size
  FROM cohort_users
  GROUP BY cohort_week_start
),

retained AS (                   -- users who came back exactly 2 weeks later
  SELECT DISTINCT
    cu.user_pseudo_id,
    cu.cohort_week_start
  FROM cohort_users cu
  JOIN `firebase-public-project.analytics_153293282.events_*` ev
    ON ev.user_pseudo_id = cu.user_pseudo_id
  WHERE ev.event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
    AND DATE_DIFF(
          DATE_TRUNC(PARSE_DATE('%Y%m%d', ev.event_date), WEEK(MONDAY)),
          cu.cohort_week_start,
          WEEK(MONDAY)
        ) = 2
),

retention_counts AS (           -- retained‑user count per cohort
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM retained
  GROUP BY cohort_week_start
)

SELECT
  cs.cohort_week_start                           AS cohort_start_monday,
  cs.cohort_size,
  COALESCE(rc.retained_users, 0)                 AS retained_users_week2,
  ROUND(SAFE_DIVIDE(rc.retained_users, cs.cohort_size) * 100, 2)
                                                AS week2_retention_rate_pct
FROM cohort_sizes cs
LEFT JOIN retention_counts rc
  USING (cohort_week_start)
ORDER BY cohort_start_monday;