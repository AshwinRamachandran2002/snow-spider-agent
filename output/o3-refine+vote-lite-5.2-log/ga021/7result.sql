/*----------------------------------------------------------
Two‑week (14‑day) retention by quick‑play event type
Cohort: users whose first <quickplay> event occurs between
        2 Jul 2018 and 16 Jul 2018 (inclusive) AND who
        generated at least one session_start in the same
        period.

Retention: user is counted as retained if he/she fires a
           session_start exactly 14 days after the
           quick‑play cohort‑entry date.
-----------------------------------------------------------*/

WITH base AS (      -- pull only the rows we need
  SELECT
      user_pseudo_id,
      event_name,
      PARSE_DATE('%Y%m%d', event_date) AS evt_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'      -- covers cohort window + 14 days
    AND (event_name = 'session_start' OR event_name LIKE '%quickplay')
),

sessions_in_window AS (      -- users that have a session during the cohort window
  SELECT DISTINCT user_pseudo_id
  FROM base
  WHERE event_name = 'session_start'
    AND evt_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
),

cohort AS (       -- first quick‑play per user & type inside the window
  SELECT
      user_pseudo_id,
      event_name                           AS quickplay_type,
      MIN(evt_date)                        AS cohort_date          -- “day 0”
  FROM base
  WHERE event_name LIKE '%quickplay'
    AND evt_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM sessions_in_window)
  GROUP BY user_pseudo_id, quickplay_type
),

retained AS (     -- session_start exactly 14 days after cohort date
  SELECT DISTINCT
      c.user_pseudo_id,
      c.quickplay_type
  FROM cohort c
  JOIN base b
    ON  b.user_pseudo_id = c.user_pseudo_id
    AND b.event_name     = 'session_start'
    AND b.evt_date       = DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
)

SELECT
    c.quickplay_type,
    COUNT(DISTINCT c.user_pseudo_id)                           AS cohort_users,
    COUNT(DISTINCT r.user_pseudo_id)                           AS retained_users,
    SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id))              AS retention_rate_14d
FROM cohort c
LEFT JOIN retained r
       ON r.user_pseudo_id = c.user_pseudo_id
      AND r.quickplay_type = c.quickplay_type
GROUP BY c.quickplay_type
ORDER BY retention_rate_14d DESC;