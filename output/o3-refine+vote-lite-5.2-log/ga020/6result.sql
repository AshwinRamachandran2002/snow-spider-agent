/* Which quick‑play event type had the lowest second‑week user retention
   (retention is defined by a “session_start” between day 8 and day 14
   after the user’s first occurrence of that quick‑play event).
*/
WITH cohort_raw AS (
  -- users’ FIRST quick‑play event between 1–15 Aug 2018
  SELECT
    event_name                               AS quickplay_event,
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)         AS cohort_date,
    ROW_NUMBER() OVER (
      PARTITION BY event_name, user_pseudo_id
      ORDER BY event_timestamp
    )                                        AS rn
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND event_name LIKE '%_quickplay'
),
cohort AS (
  SELECT quickplay_event, user_pseudo_id, cohort_date
  FROM cohort_raw
  WHERE rn = 1
),
sessions AS (
  -- all session_start events up to 29 Aug 2018
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'
    AND event_name = 'session_start'
),
retention AS (
  SELECT
    c.quickplay_event,
    COUNT(DISTINCT c.user_pseudo_id)                                         AS cohort_users,
    COUNT(DISTINCT s.user_pseudo_id)                                         AS retained_week2
  FROM cohort c
  LEFT JOIN sessions s
    ON s.user_pseudo_id = c.user_pseudo_id
   AND s.session_date BETWEEN DATE_ADD(c.cohort_date, INTERVAL 8  DAY)
                         AND DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
  GROUP BY c.quickplay_event
),
rates AS (
  SELECT
    quickplay_event,
    SAFE_DIVIDE(retained_week2, cohort_users) AS week2_retention_rate
  FROM retention
)
SELECT quickplay_event
FROM   rates
ORDER  BY week2_retention_rate ASC
LIMIT  1;