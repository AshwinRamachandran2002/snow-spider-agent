/*  Second‑week retention for Quickplay events (users whose very first session 
    happened 1–15 Aug 2018);  returns the quickplay event type with the lowest rate  */

WITH first_session AS (         -- first ever session we can see for every user
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
        AND _TABLE_SUFFIX BETWEEN '20180612' AND '20180829'     -- data we analyse
  GROUP BY user_pseudo_id
),

cohort_users AS (               -- users who first ever engaged 1–15 Aug 2018
  SELECT
    user_pseudo_id,
    first_session_date
  FROM first_session
  WHERE first_session_date BETWEEN DATE '2018-08-01' AND DATE '2018-08-15'
),

quickplay_cohort AS (           -- quickplay event types they triggered on day 0
  SELECT DISTINCT
    ev.event_name              AS quickplay_type,
    ev.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` ev
  JOIN cohort_users cu
    ON cu.user_pseudo_id = ev.user_pseudo_id
  WHERE ev.event_name LIKE '%_quickplay'
        AND PARSE_DATE('%Y%m%d', ev.event_date) = cu.first_session_date
        AND _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
),

week2_sessions AS (             -- any session_start in days 8‑14 (2nd week)
  SELECT DISTINCT
    ev.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` ev
  JOIN cohort_users cu
    ON cu.user_pseudo_id = ev.user_pseudo_id
  WHERE ev.event_name = 'session_start'
        AND DATE_DIFF(PARSE_DATE('%Y%m%d', ev.event_date), cu.first_session_date, DAY)
            BETWEEN 8 AND 14
        AND _TABLE_SUFFIX BETWEEN '20180809' AND '20180829'
)

SELECT
  quickplay_type,
  cohort_size,
  retained_users,
  ROUND(retention_rate, 4) AS retention_rate
FROM (
  SELECT
    qc.quickplay_type,
    COUNT(DISTINCT qc.user_pseudo_id)                                                   AS cohort_size,
    COUNT(DISTINCT IF(ws.user_pseudo_id IS NOT NULL, qc.user_pseudo_id, NULL))          AS retained_users,
    SAFE_DIVIDE(
      COUNT(DISTINCT IF(ws.user_pseudo_id IS NOT NULL, qc.user_pseudo_id, NULL)),
      COUNT(DISTINCT qc.user_pseudo_id)
    )                                                                                   AS retention_rate
  FROM quickplay_cohort qc
  LEFT JOIN week2_sessions ws
    ON qc.user_pseudo_id = ws.user_pseudo_id
  GROUP BY qc.quickplay_type
)
ORDER BY retention_rate ASC, quickplay_type
LIMIT 1;