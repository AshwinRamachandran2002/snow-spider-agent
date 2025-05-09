-- Cohort with the highest 4-week retention (week index = 3)
WITH first_sessions AS (
  -- Day-0: first session_start of every user (cohort = Monday of that week)
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_monday
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
week4_returns AS (
  -- Users who come back in the 4th week (week difference = 3)
  SELECT DISTINCT
    fs.user_pseudo_id,
    fs.cohort_monday
  FROM first_sessions AS fs
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = fs.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'
    AND DATE_DIFF(
          DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
          fs.cohort_monday,
          WEEK
        ) = 3
),
cohort_retention AS (
  -- 4-week retention per cohort
  SELECT
    fs.cohort_monday,
    SAFE_DIVIDE(COUNT(DISTINCT wr.user_pseudo_id),
                COUNT(DISTINCT fs.user_pseudo_id)) AS week4_retention
  FROM first_sessions AS fs
  LEFT JOIN week4_returns AS wr
    ON fs.user_pseudo_id = wr.user_pseudo_id
  GROUP BY cohort_monday
)
-- Return the Monday date of the cohort with the highest 4-week retention
SELECT FORMAT_DATE('%F', cohort_monday) AS best_cohort_monday
FROM cohort_retention
ORDER BY week4_retention DESC
LIMIT 1;