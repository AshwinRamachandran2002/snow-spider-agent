-- Which quick-play event type had the lowest week-2 retention rate?
WITH cohort AS (
  -- users’ first quick-play interaction (cohort) between 01-Aug and 15-Aug-2018
  SELECT
    e.event_name,
    e.user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', e.event_date)) AS first_event_date
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(e.event_name) LIKE '%quickplay%'
  GROUP BY e.event_name, e.user_pseudo_id
),
retained AS (
  -- those cohort users who fired ≥1 session_start 8-14 days later (week-2)
  SELECT DISTINCT
    c.event_name,
    c.user_pseudo_id
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS s
    ON s.user_pseudo_id = c.user_pseudo_id
  WHERE s.event_name = 'session_start'
    AND s._TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND DATE_DIFF(PARSE_DATE('%Y%m%d', s.event_date), c.first_event_date, DAY) BETWEEN 8 AND 14
)
SELECT
  c.event_name,
  COUNT(DISTINCT c.user_pseudo_id)                     AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)                     AS retained_users_week2,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id))        AS week2_retention_rate
FROM cohort AS c
LEFT JOIN retained AS r
  ON c.event_name = r.event_name
  AND c.user_pseudo_id = r.user_pseudo_id
GROUP BY c.event_name
ORDER BY week2_retention_rate ASC
LIMIT 1;