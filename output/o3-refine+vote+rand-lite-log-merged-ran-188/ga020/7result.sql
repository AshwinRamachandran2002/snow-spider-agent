/*  Which quick‑play event type produced the lowest 2nd–week retention
    (days 8‑14 after first engagement) for users whose first quick‑play
    event happened 1–15 Aug 2018. Retention is based on the presence of
    at least one session_start event in that 8‑14‑day window.          */

WITH quickplay_first AS (         -- users’ first quick‑play event in the cohort window
  SELECT
    event_name,
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS cohort_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND event_name LIKE '%quickplay%'
  GROUP BY event_name, user_pseudo_id
),

cohort AS (                       -- add start / end of “second week” window
  SELECT
    event_name,
    user_pseudo_id,
    cohort_date,
    DATE_ADD(cohort_date, INTERVAL 7  DAY)  AS wk2_start,   -- day 8
    DATE_ADD(cohort_date, INTERVAL 13 DAY)  AS wk2_end      -- day 14
  FROM quickplay_first
),

wk2_sessions AS (                 -- session_start events that fall in each user’s week‑2 window
  SELECT
    c.event_name,
    c.user_pseudo_id
  FROM cohort c
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = c.user_pseudo_id
   AND e.event_name     = 'session_start'
   AND PARSE_DATE('%Y%m%d', e.event_date) BETWEEN c.wk2_start AND c.wk2_end
   /* need data through 28‑Aug (=15 Aug + 13 days) */
   AND e._TABLE_SUFFIX BETWEEN '20180801' AND '20180828'
  GROUP BY c.event_name, c.user_pseudo_id
),

retention AS (                    -- cohort size & retained users per event_name
  SELECT
    c.event_name,
    COUNT(DISTINCT c.user_pseudo_id)                                AS cohort_size,
    COUNT(DISTINCT s.user_pseudo_id)                                AS retained_users,
    SAFE_DIVIDE(COUNT(DISTINCT s.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id))                   AS retention_rate
  FROM cohort c
  LEFT JOIN wk2_sessions s
    ON s.event_name = c.event_name
   AND s.user_pseudo_id = c.user_pseudo_id
  GROUP BY c.event_name
)

SELECT event_name
FROM   retention
ORDER BY retention_rate ASC, event_name
LIMIT 1;