WITH cohort AS (
  -- first time each user triggered a quick-play event inside the cohort window
  SELECT
    user_pseudo_id,
    event_name,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS cohort_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY user_pseudo_id, event_name
),
session_filter AS (   -- keep only users who actually started a session 2-Jul–16-Jul
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),
cohort_clean AS (
  SELECT c.*
  FROM cohort c
  JOIN session_filter s USING (user_pseudo_id)
),
ret_sessions AS (      -- any session exactly 14 days after cohort_date
  SELECT DISTINCT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'  -- cohort window + 14 days
    AND event_name = 'session_start'
)
SELECT
  cohort_clean.event_name,
  COUNT(*)                                                     AS cohort_users,
  SUM(IF(ret_sessions.user_pseudo_id IS NULL, 0, 1))           AS retained_users,
  ROUND(SAFE_DIVIDE(SUM(IF(ret_sessions.user_pseudo_id IS NULL, 0, 1)),
                    COUNT(*)) * 100, 2)                        AS retention_rate_pct
FROM cohort_clean
LEFT JOIN ret_sessions
  ON  ret_sessions.user_pseudo_id = cohort_clean.user_pseudo_id
  AND ret_sessions.session_date   = DATE_ADD(cohort_clean.cohort_date, INTERVAL 14 DAY)
GROUP BY cohort_clean.event_name
ORDER BY retention_rate_pct DESC;