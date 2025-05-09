WITH first_sessions AS (               -- each user’s first session & cohort week
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date))                           AS first_session_date,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_monday
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND PARSE_DATE('%Y%m%d', event_date) >= DATE '2018-07-02'
  GROUP BY user_pseudo_id
),
all_sessions AS (                      -- every later session with week index
  SELECT
    fs.user_pseudo_id,
    fs.cohort_monday,
    FLOOR(
      DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date),
                fs.first_session_date,
                DAY) / 7
    ) AS week_index
  FROM first_sessions AS fs
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = fs.user_pseudo_id
  WHERE e.event_name = 'session_start'
),
user_retention AS (                    -- did the user return in week 4? (index 3)
  SELECT
    user_pseudo_id,
    cohort_monday,
    IF(MAX(CASE WHEN week_index = 3 THEN 1 ELSE 0 END) = 1, 1, 0) AS retained_wk4
  FROM all_sessions
  GROUP BY user_pseudo_id, cohort_monday
),
cohort_stats AS (                      -- 4‑week retention rate per cohort
  SELECT
    cohort_monday,
    SAFE_DIVIDE(SUM(retained_wk4), COUNT(*)) AS retention_rate_wk4
  FROM user_retention
  GROUP BY cohort_monday
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_monday) AS best_cohort_monday
FROM cohort_stats
ORDER BY retention_rate_wk4 DESC, cohort_monday ASC
LIMIT 1;