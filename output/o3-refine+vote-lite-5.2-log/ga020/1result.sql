WITH base AS (
  SELECT
    _TABLE_SUFFIX AS table_date,
    event_name,
    user_pseudo_id,
    event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'   -- data window
),

/* Cohort: users whose FIRST quick‑play‑type event occurred 1–15 Aug 2018 */
cohorts AS (
  SELECT
    user_pseudo_id,
    event_name AS quickplay_event,
    MIN(TIMESTAMP_MICROS(event_timestamp)) AS first_ts
  FROM base
  WHERE event_name LIKE '%quickplay%'
    AND table_date BETWEEN '20180801' AND '20180815'
  GROUP BY user_pseudo_id, event_name
  HAVING DATE(first_ts) BETWEEN '2018-08-01' AND '2018-08-15'
),

/* Users from each cohort who fired a session_start during the 2nd week (days 8‑14) */
retained AS (
  SELECT DISTINCT
    c.quickplay_event,
    c.user_pseudo_id
  FROM cohorts c
  JOIN base b
    ON b.user_pseudo_id = c.user_pseudo_id
   AND b.event_name = 'session_start'
   AND TIMESTAMP_MICROS(b.event_timestamp)
       BETWEEN c.first_ts + INTERVAL 8 DAY
           AND c.first_ts + INTERVAL 14 DAY
)

/* Retention calculation & identify the event with the lowest rate */
SELECT
  c.quickplay_event,
  COUNT(DISTINCT r.user_pseudo_id)  AS retained_users,
  COUNT(DISTINCT c.user_pseudo_id)  AS cohort_size,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id)) AS retention_rate
FROM cohorts c
LEFT JOIN retained r
  ON r.quickplay_event = c.quickplay_event
 AND r.user_pseudo_id = c.user_pseudo_id
GROUP BY c.quickplay_event
ORDER BY retention_rate ASC
LIMIT 1;