-- Cohort with the highest 4-week retention (Monday date of the cohort week)
WITH first_sessions AS (         -- 1) first session date per user (from 2018-07-02 on)
  SELECT
    user_pseudo_id,
    MIN(_TABLE_SUFFIX) AS first_session_yyyymmdd
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180930'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
cohort AS (                      -- 2) assign each user to a Monday cohort week
  SELECT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', first_session_yyyymmdd), WEEK(MONDAY)) AS cohort_week
  FROM first_sessions
),
session_weeks AS (               -- 3) map every later session_start to a week index
  SELECT
    c.user_pseudo_id,
    c.cohort_week,
    DIV(
      DATE_DIFF(
        DATE_TRUNC(PARSE_DATE('%Y%m%d', e._TABLE_SUFFIX), WEEK(MONDAY)),
        c.cohort_week,
        DAY
      ),
      7
    ) AS week_index
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON c.user_pseudo_id = e.user_pseudo_id
  WHERE e._TABLE_SUFFIX BETWEEN '20180702' AND '20181003'   -- include 4 weeks after Sept-30
    AND e.event_name = 'session_start'
),
retention AS (                   -- 4) 4-week retention per cohort
  SELECT
    cohort_week,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN week_index = 3 THEN user_pseudo_id END),
      COUNT(DISTINCT user_pseudo_id)
    ) AS week4_retention
  FROM session_weeks
  GROUP BY cohort_week
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_week) AS `YYYY-MM-DD`
FROM retention
ORDER BY week4_retention DESC
LIMIT 1;