/* 2‑week retention by quick‑play event type
   – cohort: users whose FIRST <quickplay> event happened 2‑Jul‑2018–16‑Jul‑2018
             (and who had at least one session_start in the same period)
   – retained: user fired the SAME quick‑play event exactly 14 days later           */

WITH session_users AS (              -- 1. users who opened a session in the period
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

initial_quickplay AS (               -- 2. first quick‑play event per user & type
  SELECT
    user_pseudo_id,
    event_name                         AS quickplay_type,
    PARSE_DATE('%Y%m%d', event_date)   AS cohort_dt,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id, event_name
                       ORDER BY event_timestamp) AS rn
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name LIKE '%quickplay'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
),

cohort AS (                          -- 3. keep only the first occurrence
  SELECT user_pseudo_id, quickplay_type, cohort_dt
  FROM initial_quickplay
  WHERE rn = 1
),

retained AS (                        -- 4. user fired same event exactly 14 days later
  SELECT DISTINCT
    c.user_pseudo_id,
    c.quickplay_type
  FROM cohort c
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = c.user_pseudo_id
   AND e.event_name     = c.quickplay_type
   AND PARSE_DATE('%Y%m%d', e.event_date) = DATE_ADD(c.cohort_dt, INTERVAL 14 DAY)
  WHERE _TABLE_SUFFIX BETWEEN '20180716' AND '20180730'
)

-- 5. retention rate
SELECT
  c.quickplay_type,
  COUNT(DISTINCT c.user_pseudo_id)                         AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)                         AS retained_users,
  ROUND(
        COUNT(DISTINCT r.user_pseudo_id)
        / COUNT(DISTINCT c.user_pseudo_id)
       ,4)                                                 AS retention_rate
FROM cohort c
LEFT JOIN retained r
  ON  r.user_pseudo_id  = c.user_pseudo_id
  AND r.quickplay_type  = c.quickplay_type
GROUP BY c.quickplay_type
ORDER BY retention_rate DESC;