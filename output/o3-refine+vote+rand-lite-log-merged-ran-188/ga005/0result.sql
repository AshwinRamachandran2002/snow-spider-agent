-- Week-2 retention for Monday cohorts between 09-Jul-2018 and 17-Sep-2018
WITH cohort_users AS (
  -- users whose FIRST session_start happens in the cohort week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', _TABLE_SUFFIX), WEEK(MONDAY)) AS cohort_week_start
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20180930'           -- up to week of 17-Sep
    AND event_name = 'session_start'
    -- “new” user = first session day == first_touch day
    AND PARSE_DATE('%Y%m%d', _TABLE_SUFFIX) = DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
),

cohort_sizes AS (
  SELECT
    cohort_week_start,
    COUNT(DISTINCT user_pseudo_id) AS cohort_size
  FROM cohort_users
  GROUP BY cohort_week_start
),

retained_wk2 AS (
  -- cohort members who return with session_start exactly 2 weeks later
  SELECT
    cu.cohort_week_start,
    COUNT(DISTINCT e.user_pseudo_id) AS retained_wk2_users
  FROM cohort_users cu
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = cu.user_pseudo_id
  WHERE e._TABLE_SUFFIX BETWEEN '20180709' AND '20181002'          -- activity window
    AND e.event_name = 'session_start'
    AND DATE_DIFF( DATE_TRUNC(PARSE_DATE('%Y%m%d', e._TABLE_SUFFIX), WEEK(MONDAY)),
                   cu.cohort_week_start,
                   WEEK(MONDAY) ) = 2                               -- exactly 2-week gap
  GROUP BY cu.cohort_week_start
)

SELECT
  cs.cohort_week_start,
  cs.cohort_size,
  COALESCE(r.retained_wk2_users, 0)                           AS retained_wk2_users,
  SAFE_DIVIDE(COALESCE(r.retained_wk2_users, 0), cs.cohort_size) AS week2_retention_rate
FROM cohort_sizes cs
LEFT JOIN retained_wk2 r USING (cohort_week_start)
WHERE cs.cohort_week_start BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
ORDER BY cs.cohort_week_start;