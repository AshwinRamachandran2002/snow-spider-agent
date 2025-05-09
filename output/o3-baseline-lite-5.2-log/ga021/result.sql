/*  Two‑week (14‑day) retention by quick‑play event type
    Cohort window      : 02‑Jul‑2018 – 16‑Jul‑2018 (inclusive)
    Retention checked  : exactly 14 days after each user’s first quick‑play event
    Cohort restriction : only users that generated at least one `session_start`
                         between 02‑Jul‑2018 and 16‑Jul‑2018                     */

WITH session_users AS (          -- users who opened a session in the cohort window
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

quickplay_events AS (            -- quick‑play events created by those users
  SELECT
    user_pseudo_id,
    event_name                      AS quickplay_event,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND REGEXP_CONTAINS(event_name , r'_quickplay$')      -- every event that ends with “_quickplay”
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
),

cohorts AS (                     -- first (initial) quick‑play event per user & type
  SELECT
    quickplay_event,
    user_pseudo_id,
    MIN(event_date) AS cohort_date
  FROM quickplay_events
  GROUP BY quickplay_event, user_pseudo_id
),

all_events AS (                  -- any event created until two weeks after 16‑Jul‑2018
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'   -- 30‑Jul = 16‑Jul + 14
)

SELECT
  c.quickplay_event                              AS quickplay_event_type,
  COUNT(DISTINCT c.user_pseudo_id)               AS cohort_users,
  COUNT(DISTINCT e.user_pseudo_id)               AS retained_users_day14,
  SAFE_DIVIDE(COUNT(DISTINCT e.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id))  AS retention_rate_day14
FROM cohorts c
LEFT JOIN all_events e
  ON  e.user_pseudo_id = c.user_pseudo_id
  AND e.event_date    = DATE_ADD(c.cohort_date, INTERVAL 14 DAY)  -- exactly two weeks later
GROUP BY quickplay_event_type
ORDER BY retention_rate_day14 DESC;