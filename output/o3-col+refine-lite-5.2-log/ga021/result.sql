-- Two‑week (±1 day) retention after the first quick‑play event,
-- per quick‑play event type, for users that opened at least one
-- session between 02‑Jul‑2018 and 16‑Jul‑2018.

WITH   -----------------------------------------------------------------
-- 1) Users that had a `session_start` in the cohort‑definition window.
session_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM   `firebase-public-project.analytics_153293282.events_*`
  WHERE  event_date BETWEEN '20180702' AND '20180716'
    AND  event_name   = 'session_start'
),

-- 2) First quick‑play event (of each type) for those users
--    during the same window.
first_qp AS (
  SELECT  user_pseudo_id,
          event_name                     AS quickplay_type,
          MIN(TIMESTAMP_MICROS(event_timestamp)) AS first_ts
  FROM    `firebase-public-project.analytics_153293282.events_*`
  WHERE   event_date BETWEEN '20180702' AND '20180716'
    AND   LOWER(event_name) LIKE '%quickplay%'
    AND   user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
  GROUP BY user_pseudo_id, quickplay_type
),

-- 3) All later quick‑play events for those users, searched up to
--    31‑Jul‑2018 (2 weeks after the latest possible cohort date).
later_qp AS (
  SELECT  user_pseudo_id,
          event_name  AS quickplay_type,
          TIMESTAMP_MICROS(event_timestamp) AS ts
  FROM    `firebase-public-project.analytics_153293282.events_*`
  WHERE   event_date BETWEEN '20180702' AND '20180731'
    AND   LOWER(event_name) LIKE '%quickplay%'
    AND   user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
)

-- 4) Retention calculation ------------------------------------------------
SELECT
    f.quickplay_type,
    COUNT(DISTINCT f.user_pseudo_id)                                  AS cohort_size,
    COUNT(DISTINCT CASE
                      WHEN l.ts BETWEEN TIMESTAMP_ADD(f.first_ts, INTERVAL 13 DAY)
                                   AND  TIMESTAMP_ADD(f.first_ts, INTERVAL 15 DAY)
                      THEN f.user_pseudo_id
                   END)                                               AS retained_users,
    ROUND(
      COUNT(DISTINCT CASE
                        WHEN l.ts BETWEEN TIMESTAMP_ADD(f.first_ts, INTERVAL 13 DAY)
                                     AND  TIMESTAMP_ADD(f.first_ts, INTERVAL 15 DAY)
                        THEN f.user_pseudo_id
                     END)
      / COUNT(DISTINCT f.user_pseudo_id), 4)                          AS retention_rate
FROM   first_qp  AS f
LEFT JOIN later_qp AS l
       ON  l.user_pseudo_id = f.user_pseudo_id
       AND l.quickplay_type = f.quickplay_type
GROUP BY f.quickplay_type
ORDER BY retention_rate DESC, f.quickplay_type;