/* Two‑week retention after the user’s FIRST “quickplay” event (per event type)
   for users who opened a session between 02‑Jul‑2018 and 16‑Jul‑2018          */

WITH
/* 1. Users that had at least one session_start in the cohort period */
session_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'          -- cohort period
    AND event_name = 'session_start'
),

/* 2. First quickplay event of every type for those users inside the cohort period */
initial_quickplays AS (
  SELECT
    user_pseudo_id,
    event_name                    AS quickplay_event,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_event_date   -- initial day‑0 date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name LIKE '%quickplay'                             -- any “*_quickplay” event
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
  GROUP BY user_pseudo_id, quickplay_event
),

/* 3. Users that repeated THE SAME quickplay event exactly 14 days later */
retained_users AS (
  SELECT DISTINCT
    iq.user_pseudo_id,
    iq.quickplay_event
  FROM initial_quickplays iq
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id  = iq.user_pseudo_id
   AND e.event_name      = iq.quickplay_event
   AND PARSE_DATE('%Y%m%d', e.event_date)
       = DATE_ADD(iq.first_event_date, INTERVAL 14 DAY)         -- day‑14 return
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'          -- need data through 30‑Jul
)

/* 4. Final two‑week retention by quickplay event type */
SELECT
  iq.quickplay_event                               AS quickplay_event,
  COUNT(DISTINCT iq.user_pseudo_id)                AS total_users,
  COUNT(DISTINCT ru.user_pseudo_id)                AS retained_users_day14,
  SAFE_DIVIDE(COUNT(DISTINCT ru.user_pseudo_id),
              COUNT(DISTINCT iq.user_pseudo_id))   AS retention_rate_day14
FROM initial_quickplays iq
LEFT JOIN retained_users ru
  ON ru.user_pseudo_id  = iq.user_pseudo_id
 AND ru.quickplay_event = iq.quickplay_event
GROUP BY iq.quickplay_event
ORDER BY iq.quickplay_event;