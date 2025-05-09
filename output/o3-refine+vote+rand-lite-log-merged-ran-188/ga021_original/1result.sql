/* 2‑week retention (Day‑14) for every “*_quickplay” event whose first
   occurrence happens between 02‑Jul‑2018 and 16‑Jul‑2018 (inclusive).
   Only users that opened at least one session in that same period are
   considered part of the cohort.

   Definitions
   ───────────
   • Cohort user : first time the given quickplay‑event is seen for the
                   user inside the period 2018‑07‑02 … 2018‑07‑16.
   • Retained    : the same user fires ANY session_start event whose
                   timestamp is ≥14 days and <15 days after that first
                   quickplay event.                                              */

WITH
/* ─────────────── 1) users that opened a session in the cohort window ───────── */
session_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

/* ───────────── 2) first quick‑play event per user inside the window ───────────*/
cohort AS (
  SELECT
    e.user_pseudo_id,
    e.event_name,                       -- e.g. level_complete_quickplay
    MIN(e.event_timestamp) AS init_ts   -- µs; first time it happened
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND e.event_name LIKE '%quickplay'              -- any quick‑play type
    AND e.user_pseudo_id IN (SELECT user_pseudo_id  -- must have started a session
                             FROM session_users)
  GROUP BY e.user_pseudo_id, e.event_name
),

/* ───────────── 3) did the user come back 14 days later? ───────────────────────*/
returns AS (
  SELECT
    c.user_pseudo_id,
    c.event_name
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS f
    ON  f.user_pseudo_id = c.user_pseudo_id
  WHERE f._TABLE_SUFFIX BETWEEN '20180702' AND '20180731'   -- need look‑ahead
    AND f.event_name = 'session_start'
    AND f.event_timestamp BETWEEN
        c.init_ts + 14*86400*1000000        -- ≥ 14 days after first quickplay
    AND c.init_ts + 15*86400*1000000 - 1    --  < 15 days (i.e. day‑14 window)
  GROUP BY c.user_pseudo_id, c.event_name   -- one row per retained user
)

/* ─────────────────────────── 4) final retention table ─────────────────────────*/
SELECT
  c.event_name                                       AS quickplay_event,
  COUNT(DISTINCT c.user_pseudo_id)                  AS cohort_users,
  COUNT(DISTINCT r.user_pseudo_id)                  AS retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id))     AS retention_rate
FROM cohort AS c
LEFT JOIN returns AS r
  ON c.user_pseudo_id = r.user_pseudo_id
 AND c.event_name     = r.event_name
GROUP BY quickplay_event
ORDER BY quickplay_event;