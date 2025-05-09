-- 2‑week (14‑day) retention for every “quickplay” event type
-- cohort: users whose FIRST quickplay event of that type occurred 2‑16 Jul 2018
-- only users that had at least one session_start in the cohort window are considered
WITH base AS (   -- all events needed for cohort & retention windows
  SELECT
    PARSE_DATE('%Y%m%d', event_date)           AS event_dt,
    user_pseudo_id,
    event_name
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180730'          -- cohort window + 14 days
),

cohort_users AS (            -- users who opened a session in the cohort window
  SELECT DISTINCT user_pseudo_id
  FROM base
  WHERE event_name = 'session_start'
    AND event_dt BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
),

initial_quickplay AS (       -- first quickplay event per user & type in cohort window
  SELECT
    b.user_pseudo_id,
    b.event_name                              AS quickplay_type,
    MIN(b.event_dt)                           AS cohort_dt
  FROM base b
  JOIN cohort_users cu USING (user_pseudo_id)
  WHERE b.event_name LIKE '%quickplay%'       -- all quickplay‑related events
    AND b.event_dt BETWEEN DATE '2018-07-02' AND DATE '2018-07-16'
  GROUP BY b.user_pseudo_id, quickplay_type
),

cohort_size AS (             -- size of each quickplay cohort
  SELECT
    quickplay_type,
    COUNT(*) AS total_users
  FROM initial_quickplay
  GROUP BY quickplay_type
),

retained AS (                -- users who returned (session_start) exactly 14 days later
  SELECT
    iq.quickplay_type,
    COUNT(DISTINCT iq.user_pseudo_id) AS retained_users
  FROM initial_quickplay iq
  JOIN base b
    ON  b.user_pseudo_id = iq.user_pseudo_id
    AND b.event_name     = 'session_start'
    AND b.event_dt       = DATE_ADD(iq.cohort_dt, INTERVAL 14 DAY)
  GROUP BY iq.quickplay_type
)

SELECT
  cs.quickplay_type,
  cs.total_users,
  IFNULL(r.retained_users, 0)                         AS retained_users,
  ROUND(IFNULL(r.retained_users, 0) / cs.total_users, 4) AS retention_rate_2w
FROM cohort_size cs
LEFT JOIN retained r USING (quickplay_type)
ORDER BY retention_rate_2w DESC, cs.quickplay_type;