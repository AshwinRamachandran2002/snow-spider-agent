WITH cohort AS (
  -- users whose very first quick‑play event happened 1–15 Aug 2018
  SELECT
    user_pseudo_id,
    ARRAY_AGG(event_name ORDER BY event_timestamp ASC LIMIT 1)[OFFSET(0)]
        AS quickplay_event_type,
    MIN(event_timestamp) AS first_qp_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND event_name LIKE '%quickplay%'
  GROUP BY user_pseudo_id
),
second_week AS (
  -- those same users who triggered a session_start 8‑14 days later
  SELECT DISTINCT c.user_pseudo_id
  FROM cohort c
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND DATE_DIFF(
          DATE(TIMESTAMP_MICROS(e.event_timestamp)),
          DATE(TIMESTAMP_MICROS(c.first_qp_ts)),
          DAY) BETWEEN 8 AND 14
),
rates AS (
  -- retention rate per quick‑play event type
  SELECT
    quickplay_event_type,
    SAFE_DIVIDE(COUNT(DISTINCT sw.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id)) AS second_week_retention_rate
  FROM cohort c
  LEFT JOIN second_week sw
    ON c.user_pseudo_id = sw.user_pseudo_id
  GROUP BY quickplay_event_type
)
-- event with the lowest second‑week retention
SELECT
  quickplay_event_type,
  ROUND(second_week_retention_rate, 4) AS second_week_retention_rate
FROM rates
ORDER BY second_week_retention_rate ASC
LIMIT 1;