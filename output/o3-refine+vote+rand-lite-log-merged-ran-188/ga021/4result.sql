-- Two-week (14-day) retention per quick-play event type  
-- Cohort window: 2-Jul-2018 → 16-Jul-2018  
-- Only users who opened at least one session_start in the same window are considered

WITH quickplay_initial AS (      -- users’ first quick-play event inside the window
  SELECT
    user_pseudo_id,
    event_name,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_date   -- day-0 per user/event
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name LIKE '%quickplay%'
    AND user_pseudo_id IN (      -- must have fired session_start in the window
          SELECT DISTINCT user_pseudo_id
          FROM `firebase-public-project.analytics_153293282.events_*`
          WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
            AND event_name = 'session_start'
        )
  GROUP BY user_pseudo_id, event_name
),

retained AS (                    -- same user fires same event exactly 14 days later
  SELECT DISTINCT
    qi.user_pseudo_id,
    qi.event_name
  FROM quickplay_initial AS qi
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON  e.user_pseudo_id = qi.user_pseudo_id
    AND e.event_name     = qi.event_name
    AND PARSE_DATE('%Y%m%d', e.event_date) = DATE_ADD(qi.first_date, INTERVAL 14 DAY)
)

SELECT
  qi.event_name                                   AS quickplay_event_type,
  COUNT(DISTINCT qi.user_pseudo_id)               AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)                AS retained_users,
  SAFE_DIVIDE(
      COUNT(DISTINCT r.user_pseudo_id),
      COUNT(DISTINCT qi.user_pseudo_id)
  )                                               AS retention_rate_2w
FROM quickplay_initial AS qi
LEFT JOIN retained AS r
  ON  qi.user_pseudo_id = r.user_pseudo_id
  AND qi.event_name     = r.event_name
GROUP BY quickplay_event_type
ORDER BY quickplay_event_type;