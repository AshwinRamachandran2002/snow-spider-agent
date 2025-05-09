/*--------------------------------------------------------------------
  2‑week (14‑day) retention for every “quickplay” event type
  Cohort: first occurrence of each quickplay event between 2‑Jul‑2018
          and 16‑Jul‑2018 by users who opened a session in the same
          period.
  Retained: user fired ANY event exactly 14 days after the cohort day.
--------------------------------------------------------------------*/
WITH base AS (
  -- All events we might need: cohort window + 14‑day look‑ahead
  SELECT
    _TABLE_SUFFIX          AS event_date,          -- YYYYMMDD string
    user_pseudo_id,
    event_name
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'
),

eligible_users AS (
  -- Users who started at least one session in the cohort window
  SELECT DISTINCT user_pseudo_id
  FROM base
  WHERE event_name = 'session_start'
    AND event_date BETWEEN '20180702' AND '20180716'
),

cohort AS (
  -- First (initial) quickplay event per user & event type
  SELECT
    user_pseudo_id,
    event_name                  AS quickplay_event,
    MIN(event_date)             AS cohort_date               -- YYYYMMDD
  FROM base
  WHERE event_name LIKE '%quickplay'
    AND event_date BETWEEN '20180702' AND '20180716'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM eligible_users)
  GROUP BY user_pseudo_id, quickplay_event
),

retention AS (
  -- Check if user had any event exactly 14 days after cohort_date
  SELECT
    c.quickplay_event,
    COUNT(DISTINCT c.user_pseudo_id)                                            AS cohort_users,
    COUNT(DISTINCT CASE
                     WHEN b.user_pseudo_id IS NOT NULL THEN c.user_pseudo_id
                   END)                                                         AS retained_users
  FROM cohort c
  LEFT JOIN base b
    ON  b.user_pseudo_id = c.user_pseudo_id
    AND b.event_date = FORMAT_DATE(
                          '%Y%m%d',
                          DATE_ADD(PARSE_DATE('%Y%m%d', c.cohort_date),
                                   INTERVAL 14 DAY)
                        )
  GROUP BY c.quickplay_event
)

SELECT
  quickplay_event,
  cohort_users,
  retained_users,
  ROUND(SAFE_DIVIDE(retained_users, cohort_users) * 100, 4) AS retention_rate_percent
FROM retention
ORDER BY retention_rate_percent DESC;