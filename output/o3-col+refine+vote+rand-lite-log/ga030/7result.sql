WITH first_sessions AS (   -- user’s very first session and its week (Monday)
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date))                       AS first_date,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_monday
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20181008'         -- data range to examine
  GROUP BY user_pseudo_id
  HAVING cohort_monday >= '2018-07-02'                          -- start with 2-Jul-2018 cohort
),
week4_returners AS (        -- those who came back 22-28 days after first session
  SELECT DISTINCT fs.user_pseudo_id
  FROM first_sessions fs
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = fs.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180724' AND '20181105'         -- covers possible week-4 visits
    AND PARSE_DATE('%Y%m%d', e.event_date)
        BETWEEN DATE_ADD(fs.first_date, INTERVAL 22 DAY)
            AND DATE_ADD(fs.first_date, INTERVAL 28 DAY)
),
cohort_stats AS (           -- compute 4-week retention for every cohort
  SELECT
    cohort_monday,
    SAFE_DIVIDE(
      COUNTIF(user_pseudo_id IN (SELECT user_pseudo_id FROM week4_returners)),
      COUNT(*)
    ) AS week4_retention
  FROM first_sessions
  GROUP BY cohort_monday
)
-- pick the cohort with the highest week-4 retention
SELECT
  FORMAT_DATE('%F', cohort_monday) AS cohort_monday
FROM cohort_stats
ORDER BY week4_retention DESC
LIMIT 1;