WITH quickplay_events AS (
  -- every quick‑play event that occurred in August 2018
  SELECT
    user_pseudo_id,
    event_name,
    PARSE_DATE('%Y%m%d', event_date) AS event_day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND event_name LIKE '%quickplay%'          -- only quick‑play events
),

cohort AS (
  -- users whose FIRST occurrence of each quick‑play event type was 1‑15 Aug 2018
  SELECT
    user_pseudo_id,
    event_name,
    MIN(event_day) AS cohort_day
  FROM quickplay_events
  WHERE event_day BETWEEN '2018-08-01' AND '2018-08-15'
  GROUP BY user_pseudo_id, event_name
),

cohort_window AS (
  -- mark 2nd‑week window (days 8‑14 after first engagement)
  SELECT
    user_pseudo_id,
    event_name,
    cohort_day,
    DATE_ADD(cohort_day, INTERVAL 7  DAY) AS wk2_start,
    DATE_ADD(cohort_day, INTERVAL 14 DAY) AS wk2_end
  FROM cohort
),

session_events AS (
  -- all session_start events in August 2018
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS session_day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND event_name = 'session_start'
),

retention_calc AS (
  -- second‑week retention per quick‑play event type
  SELECT
    c.event_name,
    COUNT(DISTINCT c.user_pseudo_id) AS cohort_size,
    COUNT(DISTINCT CASE
                     WHEN s.session_day BETWEEN c.wk2_start AND c.wk2_end
                     THEN c.user_pseudo_id
                   END)              AS retained_users
  FROM cohort_window   AS c
  LEFT JOIN session_events AS s
    ON s.user_pseudo_id = c.user_pseudo_id
    AND s.session_day  BETWEEN c.wk2_start AND c.wk2_end
  GROUP BY c.event_name
)

-- event type with the LOWEST 2nd‑week retention
SELECT
  event_name,
  SAFE_DIVIDE(retained_users, cohort_size) AS second_week_retention_rate
FROM retention_calc
ORDER BY second_week_retention_rate ASC
LIMIT 1;