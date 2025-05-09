-- Quick‑play event with the lowest 2‑nd‑week (days 8‑14) retention
WITH base AS (
  SELECT
      _TABLE_SUFFIX AS evt_dt,                 -- yyyymmdd
      user_pseudo_id,
      event_name,
      event_timestamp                          -- micro‑seconds
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'   -- cohort window + 2‑week look‑ahead
),

-- first time each user triggered a “*_quickplay” event in the cohort window
cohort AS (
  SELECT
      user_pseudo_id,
      event_name,
      MIN(event_timestamp) AS first_ts
  FROM base
  WHERE event_name LIKE '%quickplay%'                    -- any quick‑play event
    AND evt_dt BETWEEN '20180801' AND '20180815'         -- cohort definition
  GROUP BY user_pseudo_id, event_name
),

-- all session_start events (used to decide retention)
sessions AS (
  SELECT
      user_pseudo_id,
      TIMESTAMP_MICROS(event_timestamp) AS sess_ts
  FROM base
  WHERE event_name = 'session_start'
),

-- calculate 2‑nd‑week retention per event
retention AS (
  SELECT
      c.event_name,
      COUNT(DISTINCT c.user_pseudo_id) AS cohort_users,
      COUNT(DISTINCT IF(
              sess.sess_ts BETWEEN
                  TIMESTAMP_ADD(TIMESTAMP_MICROS(c.first_ts), INTERVAL 7  DAY)
              AND TIMESTAMP_ADD(TIMESTAMP_MICROS(c.first_ts), INTERVAL 14 DAY),
              c.user_pseudo_id,
              NULL)
          ) AS retained_users
  FROM cohort c
  LEFT JOIN sessions sess
         ON sess.user_pseudo_id = c.user_pseudo_id
  GROUP BY c.event_name
),

ranked AS (
  SELECT
      event_name,
      SAFE_DIVIDE(retained_users, cohort_users) AS retention_rate
  FROM retention
)

SELECT event_name
FROM ranked
WHERE retention_rate IS NOT NULL
ORDER BY retention_rate ASC, event_name
LIMIT 1;