/*  Quick‑play event that shows the worst 2nd‑week retention
    Cohort: users whose FIRST interaction with a given *quickplay* event
            happened between 1‑Aug‑2018 and 15‑Aug‑2018 (inclusive)
    Retention: user fired at least one `session_start` between day 8‑14 (inclusive)
               after that first interaction                                             */

WITH cohort AS (           -- first quick‑play interaction per user & event type
  SELECT
      event_name,                       -- e.g. level_complete_quickplay
      user_pseudo_id,
      MIN( PARSE_DATE('%Y%m%d', event_date) ) AS cohort_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'      -- tables to scan
    AND event_name LIKE '%quickplay'                         -- quick‑play events
  GROUP BY event_name, user_pseudo_id
),

retention_flag AS (        -- did that user come back (session_start) on days 8‑14?
  SELECT
      c.event_name,
      c.user_pseudo_id,
      -- user is retained if at least one matching session_start exists
      IF( COUNTIF(s.user_pseudo_id IS NOT NULL) > 0 , 1, 0) AS is_retained
  FROM cohort AS c
  LEFT JOIN `firebase-public-project.analytics_153293282.events_*`  AS s
    ON  s.user_pseudo_id = c.user_pseudo_id
    AND s.event_name     = 'session_start'
    AND PARSE_DATE('%Y%m%d', s.event_date)
          BETWEEN DATE_ADD(c.cohort_date, INTERVAL 8  DAY)
              AND DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
    -- scan tables at least until end‑Oct to cover the window
    AND s._TABLE_SUFFIX BETWEEN '20180801' AND '20181031'
  GROUP BY c.event_name, c.user_pseudo_id
),

rates AS (                 -- aggregate to compute retention rate per event type
  SELECT
      event_name,
      COUNT(DISTINCT user_pseudo_id)                                   AS cohort_users,
      COUNTIF(is_retained = 1)                                         AS retained_users,
      SAFE_DIVIDE( COUNTIF(is_retained = 1),
                   COUNT(DISTINCT user_pseudo_id) )                    AS retention_rate
  FROM retention_flag
  GROUP BY event_name
)

SELECT
    event_name                       AS worst_quickplay_event,
    cohort_users,
    retained_users,
    retention_rate
FROM rates
ORDER BY retention_rate ASC          -- lowest retention first
LIMIT 1;