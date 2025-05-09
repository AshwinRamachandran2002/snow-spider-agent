/* Two‑week (14‑day) retention by quick‑play event type
   Cohort: users whose FIRST occurrence of each quick‑play event happened
           between 2 Jul 2018 and 16 Jul 2018 **and** who fired a
           `session_start` in the same period.

   Retained: user fires the SAME quick‑play event exactly 14 days
             after his / her cohort date.

   Period scanned: 2 Jul 2018 – 30 Jul 2018  (16 Jul + 14 days)          */

WITH base AS (
  SELECT
      user_pseudo_id,
      event_name,
      PARSE_DATE('%Y%m%d', event_date)            AS event_dt
  FROM
      `firebase-public-project.analytics_153293282.events_*`
  WHERE
      _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'     -- scan cohort & look‑ahead days
      AND ( event_name = 'session_start'
            OR event_name LIKE '%quickplay%' )            -- restrict to rows we really need
),

/* users who actually started a session in the cohort window */
session_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM   base
  WHERE  event_name = 'session_start'
    AND  event_dt BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
),

/* first (initial) quick‑play event per user & event type inside the cohort window */
quickplay_initial AS (
  SELECT
      su.user_pseudo_id,
      b.event_name                 AS quickplay_event,
      MIN(b.event_dt)              AS cohort_date
  FROM   base b
  JOIN   session_users su
         USING (user_pseudo_id)
  WHERE  b.event_name LIKE '%quickplay%'
    AND  b.event_dt BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
  GROUP BY
      su.user_pseudo_id,
      quickplay_event
),

/* retention check : same quick‑play event exactly 14 days later */
retention AS (
  SELECT
      qi.quickplay_event,
      COUNT(DISTINCT qi.user_pseudo_id)                       AS cohort_users,
      COUNT(DISTINCT r.user_pseudo_id)                        AS retained_users
  FROM   quickplay_initial qi
  LEFT JOIN base r
         ON  r.user_pseudo_id = qi.user_pseudo_id
         AND r.event_name     = qi.quickplay_event
         AND r.event_dt       = DATE_ADD(qi.cohort_date, INTERVAL 14 DAY)
  GROUP BY qi.quickplay_event
)

SELECT
    quickplay_event,
    cohort_users,
    retained_users,
    SAFE_DIVIDE(retained_users, cohort_users) AS retention_rate_2w
FROM   retention
ORDER  BY quickplay_event;