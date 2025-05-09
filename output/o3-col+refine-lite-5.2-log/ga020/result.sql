-- Which Quick‑play event type has the lowest week‑2 retention rate?
WITH cohort AS (
  -- users whose FIRST quick‑play event occurred 1–15 Aug 2018
  SELECT
    user_pseudo_id,
    event_name                 AS quickplay_type,
    MIN(event_timestamp)       AS first_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND event_name LIKE '%quickplay%'
  GROUP BY user_pseudo_id, quickplay_type
),
retained AS (
  -- those users who fired a session_start in days 8‑14 after first engagement
  SELECT DISTINCT
    c.quickplay_type,
    c.user_pseudo_id
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS s
    ON  s.user_pseudo_id = c.user_pseudo_id
    AND s.event_name     = 'session_start'
    AND s.event_timestamp BETWEEN c.first_ts + 604800000000         -- +7 days
                              AND c.first_ts + 1209600000000        -- +14 days
    AND s._TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
),
rates AS (
  -- calculate week‑2 retention rates
  SELECT
    c.quickplay_type,
    SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id)) AS week2_retention_rate
  FROM cohort AS c
  LEFT JOIN retained AS r
    ON r.quickplay_type = c.quickplay_type
   AND r.user_pseudo_id = c.user_pseudo_id
  GROUP BY c.quickplay_type
)
-- return the quick‑play event with the LOWEST week‑2 retention
SELECT quickplay_type
FROM   rates
ORDER  BY week2_retention_rate ASC
LIMIT 1;