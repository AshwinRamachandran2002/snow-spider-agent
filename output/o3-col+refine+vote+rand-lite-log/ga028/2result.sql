-- 7-day (Monday-based) retention for users whose first session falls in the week that
-- starts on 2018-07-02.  Counts events only up to (and including) 2018-10-02.

WITH sessions AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)                 AS activity_date,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', _TABLE_SUFFIX),
               WEEK(MONDAY))                            AS activity_week
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181002'   -- scan range
),

-- first time we ever see a session_start per user
first_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS first_session_date
  FROM sessions
  GROUP BY user_pseudo_id
),

-- Cohort = users whose first session is during week of 2018-07-02
cohort AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_week
  FROM first_sessions
  WHERE first_session_date BETWEEN '2018-07-02' AND '2018-07-08'
),

-- All later weekly activity for cohort users (capped at 2018-10-02)
activity AS (
  SELECT
    s.user_pseudo_id,
    c.cohort_week,
    s.activity_week
  FROM sessions AS s
  JOIN cohort  AS c USING (user_pseudo_id)
  WHERE s.activity_date <= '2018-10-02'                  -- hard stop
),

-- Raw retention counts by week offset
retention_raw AS (
  SELECT
    DATE_DIFF(activity_week, cohort_week, WEEK(MONDAY)) AS week_number,
    COUNT(DISTINCT user_pseudo_id)                      AS retained_users
  FROM activity
  GROUP BY week_number
)

-- Pivot into the requested Week-0 … Week-4 view
SELECT
  (SELECT COUNT(*) FROM cohort)                                          AS week0_new_users,
  MAX(CASE WHEN week_number = 0 THEN retained_users END)                 AS week0,
  MAX(CASE WHEN week_number = 1 THEN retained_users END)                 AS week1,
  MAX(CASE WHEN week_number = 2 THEN retained_users END)                 AS week2,
  MAX(CASE WHEN week_number = 3 THEN retained_users END)                 AS week3,
  MAX(CASE WHEN week_number = 4 THEN retained_users END)                 AS week4
FROM retention_raw;