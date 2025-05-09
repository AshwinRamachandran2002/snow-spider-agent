-- Week‑2 retention for weekly cohorts (Mon‑Sun) between 2018‑07‑09 and 2018‑09‑17
WITH session_events AS (
  -- all session_start events inside the analysis window
  SELECT
    user_pseudo_id,
    DATE(PARSE_DATE('%Y%m%d', event_date))       AS event_date,
    TIMESTAMP_MICROS(user_first_touch_timestamp) AS first_touch_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    -- restrict scan to the cohorts and their +2‑week window
    AND _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'
),

first_sessions AS (
  -- first session_start date per user
  SELECT
    user_pseudo_id,
    MIN(event_date)        AS first_session_date,
    MIN(first_touch_ts)    AS first_touch_ts
  FROM session_events
  GROUP BY user_pseudo_id
),

new_users AS (
  -- users whose first session date equals their first touch date
  SELECT
    user_pseudo_id,
    first_session_date,
    DATE_TRUNC(first_session_date , WEEK(MONDAY)) AS cohort_week_start
  FROM first_sessions
  WHERE first_session_date = DATE(first_touch_ts)
    AND DATE_TRUNC(first_session_date , WEEK(MONDAY))
        BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),

week2_activity AS (
  -- users who have a session_start during the 2nd week after their cohort week
  SELECT DISTINCT
    s.user_pseudo_id,
    n.cohort_week_start
  FROM session_events AS s
  JOIN new_users     AS n
    ON s.user_pseudo_id = n.user_pseudo_id
  WHERE s.event_date BETWEEN DATE_ADD(n.cohort_week_start, INTERVAL 14 DAY)
                         AND DATE_ADD(n.cohort_week_start, INTERVAL 20 DAY)   -- Monday‑Sunday of week 2
)

SELECT
  n.cohort_week_start                              AS cohort_week_start,
  COUNT(DISTINCT n.user_pseudo_id)  AS cohort_users,
  COUNT(DISTINCT w.user_pseudo_id)  AS retained_users_week2,
  ROUND(
    SAFE_DIVIDE(COUNT(DISTINCT w.user_pseudo_id),
                COUNT(DISTINCT n.user_pseudo_id)) * 100,
    2
  )                                                AS week2_retention_rate_percent
FROM new_users n
LEFT JOIN week2_activity w
       ON n.user_pseudo_id     = w.user_pseudo_id
      AND n.cohort_week_start  = w.cohort_week_start
GROUP BY n.cohort_week_start
ORDER BY n.cohort_week_start;