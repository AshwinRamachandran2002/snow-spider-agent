-- Week‑2 retention by weekly acquisition cohort
WITH session_events AS (
  -- all session_start events in the period of interest
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)                  AS event_dt,
    TIMESTAMP_MICROS(user_first_touch_timestamp)      AS first_touch_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'   -- limit to tables we need
    AND event_name = 'session_start'
    AND event_date BETWEEN '20180709' AND '20181002'
),

first_sessions AS (
  -- first session_start per user
  SELECT
    user_pseudo_id,
    MIN(event_dt)                         AS first_session_date,
    ANY_VALUE(first_touch_ts)             AS first_touch_ts
  FROM session_events
  GROUP BY user_pseudo_id
),

cohort_users AS (
  -- keep only NEW users (first session matches first‑touch date)
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week_start
  FROM first_sessions
  WHERE
    first_session_date = DATE(first_touch_ts)          -- new users only
    AND first_session_date BETWEEN '2018-07-09' AND '2018-09-30'
),

retention_flags AS (
  -- flag users who came back in week 2 (day 14‑20 after cohort week start)
  SELECT
    cu.user_pseudo_id,
    cu.cohort_week_start,
    COUNTIF(
      se.event_dt >= cu.cohort_week_start + 14
      AND se.event_dt <  cu.cohort_week_start + 21
    ) > 0                                             AS retained_wk2
  FROM cohort_users cu
  LEFT JOIN session_events se
    ON se.user_pseudo_id = cu.user_pseudo_id
  GROUP BY cu.user_pseudo_id, cu.cohort_week_start
),

aggregated AS (
  SELECT
    cohort_week_start                                   AS cohort_date,
    COUNT(*)                                            AS cohort_size,
    SUM(CASE WHEN retained_wk2 THEN 1 ELSE 0 END)       AS retained_users
  FROM retention_flags
  WHERE cohort_week_start BETWEEN '2018-07-09' AND '2018-09-17'
  GROUP BY cohort_week_start
)

SELECT
  cohort_date,
  ROUND(SAFE_DIVIDE(retained_users, cohort_size) * 100, 2) AS week2_retention_rate
FROM aggregated
ORDER BY cohort_date;