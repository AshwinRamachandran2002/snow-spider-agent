-- 14-day retention for each “quickplay” event type
-- cohort = users that had at least one `session_start` between 2–16 Jul 2018
-- retained = same user fires the same quick-play event ≥14 days (1 209 600 000 000 µs) later

WITH cohort_users AS (               -- users who started a session in the window
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

base AS (                            -- first quick-play per (user, event_type) in window
  SELECT
    event_name              AS quickplay_type,
    user_pseudo_id,
    MIN(event_timestamp)    AS first_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(event_name) LIKE '%quickplay%'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM cohort_users)
  GROUP BY quickplay_type, user_pseudo_id
),

retained AS (                        -- repeat of the SAME quick-play ≥14 days later
  SELECT DISTINCT
    b.quickplay_type,
    b.user_pseudo_id
  FROM base b
  JOIN `firebase-public-project.analytics_153293282.events_*` q
    ON q.event_name      = b.quickplay_type
   AND q.user_pseudo_id  = b.user_pseudo_id
   AND q.event_timestamp >= b.first_ts + 1209600000000   -- 14 days in µs
)

SELECT
  b.quickplay_type,
  COUNT(DISTINCT b.user_pseudo_id)               AS users_initial,
  COUNT(DISTINCT r.user_pseudo_id)               AS users_retained,
  ROUND(COUNT(DISTINCT r.user_pseudo_id)
        / NULLIF(COUNT(DISTINCT b.user_pseudo_id),0), 4) AS retention_rate
FROM base b
LEFT JOIN retained r
       ON r.quickplay_type = b.quickplay_type
      AND r.user_pseudo_id = b.user_pseudo_id
GROUP BY b.quickplay_type
ORDER BY retention_rate DESC;