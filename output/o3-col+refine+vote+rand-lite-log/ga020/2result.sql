-- Which quick-play event type has the lowest week-2 retention
WITH cohort AS (
  -- users’ first day firing each quick-play event (Aug 1–15 2018)
  SELECT
    event_name,
    user_pseudo_id,
    MIN(DATE(TIMESTAMP_MICROS(event_timestamp))) AS cohort_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY event_name, user_pseudo_id
),
retained AS (
  -- those same users who come back 8-14 days later (session_start)
  SELECT DISTINCT
    c.event_name,
    c.user_pseudo_id
  FROM cohort c
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND DATE_DIFF(DATE(TIMESTAMP_MICROS(e.event_timestamp)), c.cohort_date, DAY)
        BETWEEN 8 AND 14
)
SELECT
  c.event_name,
  COUNT(DISTINCT c.user_pseudo_id)                         AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)                         AS retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id))            AS week2_retention
FROM cohort c
LEFT JOIN retained r
  ON r.event_name = c.event_name
 AND r.user_pseudo_id = c.user_pseudo_id
GROUP BY c.event_name
ORDER BY week2_retention
LIMIT 1;