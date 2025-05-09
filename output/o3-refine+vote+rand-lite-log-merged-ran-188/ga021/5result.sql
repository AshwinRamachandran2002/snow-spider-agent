-- Two-week retention for every “quickplay” event type
WITH cohort AS (
  /* Day-0 cohort: users whose FIRST quickplay event happened
     between 02-Jul-2018 and 16-Jul-2018
     (keep only users that also fired a session_start in the same period) */
  SELECT
    user_pseudo_id,
    event_name                                   AS quickplay_type,
    MIN(PARSE_DATE('%Y%m%d', event_date))        AS first_quickplay_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(event_name) LIKE '%quickplay%'
    AND user_pseudo_id IN (                     -- active users only
        SELECT DISTINCT user_pseudo_id
        FROM `firebase-public-project.analytics_153293282.events_*`
        WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
          AND event_name = 'session_start')
  GROUP BY user_pseudo_id, quickplay_type
),
retained AS (
  /* Users who came back exactly 14 days later with a session_start */
  SELECT DISTINCT
    c.user_pseudo_id,
    c.quickplay_type
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS s
    ON  s.user_pseudo_id = c.user_pseudo_id
    AND s.event_name     = 'session_start'
    AND PARSE_DATE('%Y%m%d', s.event_date)
        = DATE_ADD(c.first_quickplay_date, INTERVAL 14 DAY)
    AND _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'   -- covers 14-day window
)
SELECT
  c.quickplay_type,
  COUNT(DISTINCT c.user_pseudo_id)              AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)              AS retained_users,
  ROUND(100 * COUNT(DISTINCT r.user_pseudo_id)
            / COUNT(DISTINCT c.user_pseudo_id), 2) AS retention_rate_2w
FROM cohort AS c
LEFT JOIN retained AS r
       ON r.user_pseudo_id  = c.user_pseudo_id
      AND r.quickplay_type  = c.quickplay_type
GROUP BY c.quickplay_type
ORDER BY retention_rate_2w DESC;