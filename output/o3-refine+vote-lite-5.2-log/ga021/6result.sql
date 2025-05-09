/* 14‑day (two‑week) retention after a user’s FIRST quick‑play event
   for users whose first session fell between 2‑Jul‑2018 and 16‑Jul‑2018
   Results are broken out by the quick‑play event type that was
   triggered first by each user.                                              */

WITH
/*---------------------------------------------------------------------------
  1.  Cohort definition – users whose first session is in the requested
      window (inclusive).
----------------------------------------------------------------------------*/
cohort AS (
  SELECT
      user_pseudo_id,
      MIN(event_timestamp) AS first_session_ts          -- keep for speed checks
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),

/*---------------------------------------------------------------------------
  2.  All quick‑play events fired by cohort users within the whole period
      we need to look at (latest cohort start 16‑Jul plus 14 days = 30‑Jul).
----------------------------------------------------------------------------*/
quickplay_events AS (
  SELECT
      e.user_pseudo_id,
      e.event_name,
      e.event_timestamp
  FROM `firebase-public-project.analytics_153293282.events_*`   AS e
  JOIN cohort                                                    AS c
    ON c.user_pseudo_id = e.user_pseudo_id
  WHERE e._TABLE_SUFFIX BETWEEN '20180702' AND '20180730'
    AND e.event_name LIKE '%_quickplay'        -- e.g. level_start_quickplay
),

/*---------------------------------------------------------------------------
  3.  Each user’s FIRST quick‑play event (any type) – this sets
      the “day 0” for retention and gives us the quick‑play type
      we will split the cohort by.
----------------------------------------------------------------------------*/
first_qp_per_user AS (
  SELECT
      user_pseudo_id,
      ARRAY_AGG(STRUCT(event_name, event_timestamp)
                ORDER BY event_timestamp
                LIMIT 1)[OFFSET(0)].event_name      AS first_qp_event,
      ARRAY_AGG(event_timestamp ORDER BY event_timestamp LIMIT 1)[OFFSET(0)]
                                                   AS first_qp_ts
  FROM quickplay_events
  GROUP BY user_pseudo_id
),

/*---------------------------------------------------------------------------
  4.  Size of each cohort bucket (by quick‑play type).
----------------------------------------------------------------------------*/
cohort_sizes AS (
  SELECT
      first_qp_event,
      COUNT(DISTINCT user_pseudo_id) AS cohort_users
  FROM first_qp_per_user
  GROUP BY first_qp_event
),

/*---------------------------------------------------------------------------
  5.  Look for any event fired exactly 14 days after the first quick‑play
      event (N‑day retention where N = 14).  We only need to know
      whether the user was active, so DISTINCT user list is enough.
----------------------------------------------------------------------------*/
day14_activity AS (
  SELECT DISTINCT
      f.first_qp_event,
      f.user_pseudo_id
  FROM first_qp_per_user          AS f
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = f.user_pseudo_id
  WHERE e._TABLE_SUFFIX BETWEEN '20180702' AND '20180730'
    -- difference between event day and first quick‑play day = 14
    AND DATE_DIFF(
          DATE(TIMESTAMP_MICROS(e.event_timestamp)),
          DATE(TIMESTAMP_MICROS(f.first_qp_ts)),
          DAY) = 14
)

/*---------------------------------------------------------------------------
  6.  Final retention calculation.
----------------------------------------------------------------------------*/
SELECT
    cs.first_qp_event                                AS quickplay_event_type,
    cs.cohort_users,
    COUNT(DISTINCT da.user_pseudo_id) AS retained_users_after_2_weeks,
    SAFE_DIVIDE(COUNT(DISTINCT da.user_pseudo_id), cs.cohort_users)
        AS retention_rate_2_weeks
FROM cohort_sizes      AS cs
LEFT JOIN day14_activity AS da
       ON cs.first_qp_event = da.first_qp_event
GROUP BY quickplay_event_type, cohort_users
ORDER BY retention_rate_2_weeks DESC;