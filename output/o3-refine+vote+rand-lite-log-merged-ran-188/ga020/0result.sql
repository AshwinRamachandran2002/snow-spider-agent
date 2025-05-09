-- Quick‑play event that shows the lowest second‑week retention
-- for users whose first quick‑play action was between 1–15 Aug 2018
WITH cohort AS (
  /* 1. First quick‑play event per user in the cohort window */
  SELECT
    user_pseudo_id,
    event_name                                   AS quickplay_event_type,
    PARSE_DATE('%Y%m%d', event_date)             AS cohort_date
  FROM (
    SELECT
      user_pseudo_id,
      event_name,
      event_date,
      event_timestamp,
      ROW_NUMBER() OVER (PARTITION BY user_pseudo_id
                         ORDER BY event_timestamp) AS rn
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
      AND event_name LIKE '%quickplay'
  )
  WHERE rn = 1
),
retained AS (
  /* 2. Users who fired a session_start in days 8‑14 after their cohort date */
  SELECT DISTINCT
    c.user_pseudo_id,
    c.quickplay_event_type
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND PARSE_DATE('%Y%m%d', e.event_date)
        BETWEEN DATE_ADD(c.cohort_date, INTERVAL 8 DAY)
            AND DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
    AND _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'
)
SELECT
  c.quickplay_event_type,
  COUNT(DISTINCT r.user_pseudo_id)                               AS retained_users,
  COUNT(DISTINCT c.user_pseudo_id)                               AS cohort_users,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id))                  AS second_week_retention_rate
FROM cohort AS c
LEFT JOIN retained AS r
  ON  r.user_pseudo_id       = c.user_pseudo_id
  AND r.quickplay_event_type = c.quickplay_event_type
GROUP BY c.quickplay_event_type
ORDER BY second_week_retention_rate
LIMIT 1;