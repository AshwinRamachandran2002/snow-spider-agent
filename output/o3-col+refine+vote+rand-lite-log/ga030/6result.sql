/*  Best-retaining cohort (week-4) among users whose first session is on/after 2018-07-02 */
WITH first_sessions AS (      -- each user’s first session mapped to the Monday of that week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'            -- shards to inspect
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
activity AS (                 -- all session_start events for those cohort users
  SELECT
    fs.user_pseudo_id,
    fs.cohort_week,
    DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), fs.cohort_week, WEEK(MONDAY)) AS weeks_since
  FROM first_sessions fs
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON  e.user_pseudo_id = fs.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'
),
retention AS (                -- cohort sizes and week-4 retained users
  SELECT
    cohort_week,
    COUNT(DISTINCT user_pseudo_id)                                          AS cohort_size,
    COUNT(DISTINCT IF(weeks_since = 4, user_pseudo_id, NULL))              AS retained_week4
  FROM activity
  GROUP BY cohort_week
),
ranked AS (                   -- rank cohorts by highest week-4 retention rate
  SELECT
    cohort_week,
    SAFE_DIVIDE(retained_week4, cohort_size)                               AS retention_rate,
    ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(retained_week4, cohort_size) DESC) AS rn
  FROM retention
)
SELECT FORMAT_DATE('%F', cohort_week) AS best_cohort_monday
FROM   ranked
WHERE  rn = 1;