-- best-performing cohort (based on 4-th-week retention)
WITH first_session AS (          -- users grouped by the Monday of their very first session
  SELECT
    user_pseudo_id,
    DATE_TRUNC(DATE(TIMESTAMP_MICROS(MIN(event_timestamp))), WEEK(MONDAY)) 
      AS cohort_monday
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
        -- consider cohorts whose first sessions start on/after 2-Jul-2018
        AND _TABLE_SUFFIX BETWEEN '20180702' AND '20180903'
  GROUP BY user_pseudo_id
),
retention AS (                   -- 4-th-week returns for every cohort
  SELECT
    f.cohort_monday,
    COUNT(DISTINCT f.user_pseudo_id)                   AS cohort_size,
    COUNT(DISTINCT r.user_pseudo_id)                   AS retained_wk4
  FROM first_session f
  LEFT JOIN `firebase-public-project.analytics_153293282.events_*` r
    ON  r.user_pseudo_id = f.user_pseudo_id
    AND r.event_name     = 'session_start'
    AND DATE(TIMESTAMP_MICROS(r.event_timestamp))
        BETWEEN DATE_ADD(f.cohort_monday, INTERVAL 21 DAY)
            AND DATE_ADD(f.cohort_monday, INTERVAL 27 DAY)      -- 4-th-week window
    AND r._TABLE_SUFFIX BETWEEN '20180702' AND '20180930'        -- data needed for week-4
  GROUP BY f.cohort_monday
),
ranked AS (
  SELECT
    cohort_monday,
    SAFE_DIVIDE(retained_wk4, cohort_size) AS wk4_retention_rate
  FROM retention
)
SELECT FORMAT_DATE('%F', cohort_monday) AS best_cohort_monday
FROM ranked
ORDER BY wk4_retention_rate DESC
LIMIT 1;