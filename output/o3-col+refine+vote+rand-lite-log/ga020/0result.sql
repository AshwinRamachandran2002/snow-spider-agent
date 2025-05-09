--  Second-week retention for users who first triggered a “quickplay” event
--  between 01-Aug-2018 and 15-Aug-2018.  
--  Returns the event with the single lowest retention rate.

WITH cohort AS (
  -- Users’ first “quickplay” interaction (cohort definition)
  SELECT
    event_name,
    user_pseudo_id,
    MIN(event_timestamp) AS first_event_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'      -- cohort window
    AND LOWER(event_name) LIKE '%quickplay%'                 -- quickplay events
  GROUP BY event_name, user_pseudo_id
),
second_week AS (
  -- Those same users who came back with a session_start 8-14 days later
  SELECT
    c.event_name,
    c.user_pseudo_id
  FROM cohort c
  JOIN `firebase-public-project.analytics_153293282.events_*` s
    ON  s.user_pseudo_id = c.user_pseudo_id
    AND s.event_name     = 'session_start'
    AND s._TABLE_SUFFIX BETWEEN '20180801' AND '20180829'    -- return-tracking window
    AND TIMESTAMP_DIFF(
          TIMESTAMP_MICROS(s.event_timestamp),
          TIMESTAMP_MICROS(c.first_event_ts),
          DAY) BETWEEN 8 AND 14
)
SELECT
  coh.event_name               AS lowest_retention_event,
  SAFE_DIVIDE(
    COUNT(DISTINCT sw.user_pseudo_id),
    COUNT(DISTINCT coh.user_pseudo_id)
  )                            AS retention_rate
FROM cohort coh
LEFT JOIN second_week sw
  ON  coh.event_name    = sw.event_name
  AND coh.user_pseudo_id = sw.user_pseudo_id
GROUP BY coh.event_name
ORDER BY retention_rate ASC
LIMIT 1;