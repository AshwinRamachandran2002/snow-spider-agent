/*  Quick‑play event type with the lowest 2nd‑week retention (users first engaged 1–15 Aug 2018) */
WITH
-- 1) first time each user triggered every quick‑play event in the cohort window
initial_engagement AS (
  SELECT
    event_name,
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_event_date
  FROM `firebase-public-project.analytics_153293282.events_201808*`
  WHERE event_name LIKE '%quickplay%'                         -- quick‑play events
    AND PARSE_DATE('%Y%m%d', event_date) BETWEEN DATE '2018-08-01' AND DATE '2018-08-15'
  GROUP BY event_name, user_pseudo_id
),

-- 2) users who came back (session_start) in days 8‑14 after their first engagement
retained AS (
  SELECT DISTINCT
    ie.event_name,
    ie.user_pseudo_id
  FROM initial_engagement AS ie
  JOIN `firebase-public-project.analytics_153293282.events_201808*` AS ev
    ON ev.user_pseudo_id = ie.user_pseudo_id
  WHERE ev.event_name = 'session_start'
    AND PARSE_DATE('%Y%m%d', ev.event_date)
        BETWEEN DATE_ADD(ie.first_event_date, INTERVAL 7 DAY)
            AND DATE_ADD(ie.first_event_date, INTERVAL 13 DAY)
)

-- 3) retention calculation and selection of the lowest‑performing quick‑play event
SELECT
  ie.event_name                         AS quickplay_event,
  COUNT(DISTINCT ie.user_pseudo_id)     AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)      AS retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT ie.user_pseudo_id)) AS second_week_retention_rate
FROM initial_engagement AS ie
LEFT JOIN retained AS r
  ON r.event_name = ie.event_name
 AND r.user_pseudo_id = ie.user_pseudo_id
GROUP BY quickplay_event
ORDER BY second_week_retention_rate ASC
LIMIT 1;