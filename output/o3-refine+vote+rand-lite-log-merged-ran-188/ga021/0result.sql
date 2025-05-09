/*  Two–week retention by quick-play event type
    Cohort: users who fired at least one `session_start`
            between 02-Jul-2018 and 16-Jul-2018
*/
WITH session_users AS (        -- users that started a session in the cohort window
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
    AND user_pseudo_id IS NOT NULL
),

cohort AS (                    -- first quick-play event per user & type
  SELECT
    e.user_pseudo_id,
    e.event_name,
    MIN(PARSE_DATE('%Y%m%d', e.event_date)) AS cohort_date
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN session_users  su
    ON su.user_pseudo_id = e.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND e.event_name LIKE '%quickplay%'          -- quick-play events only
  GROUP BY e.user_pseudo_id, e.event_name
),

retained AS (                  -- users active exactly 14 days after cohort date
  SELECT DISTINCT
    c.user_pseudo_id,
    c.event_name
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON  e.user_pseudo_id = c.user_pseudo_id
    AND PARSE_DATE('%Y%m%d', e.event_date)
        = DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'   -- include look-ahead window
)

SELECT
  c.event_name,
  COUNT(DISTINCT c.user_pseudo_id)                               AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)                               AS retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id))                  AS two_week_retention_rate
FROM cohort   AS c
LEFT JOIN retained AS r
  ON r.user_pseudo_id = c.user_pseudo_id
 AND r.event_name    = c.event_name
GROUP BY c.event_name
ORDER BY c.event_name;