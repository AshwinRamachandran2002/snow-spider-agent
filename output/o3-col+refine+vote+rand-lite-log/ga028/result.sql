-- 7-day retention for users whose first session_start fell in the week
-- Mon 02-Jul-2018  →  Sun 08-Jul-2018 (Week 0).  
-- Retention counted for Weeks 1-4, using Monday-based weeks,  
-- considering events up to (and including) 02-Oct-2018.

WITH first_sessions AS (
  -- Earliest session_start for every user in the entire observation window
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181002'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
cohort AS (
  -- Users whose very first session falls inside Week 0 (02-Jul-2018 → 08-Jul-2018)
  SELECT user_pseudo_id
  FROM first_sessions
  WHERE first_session_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),
weekly_flags AS (
  -- Flag every cohort user in Week 0
  SELECT
    user_pseudo_id,
    0 AS weeks_since
  FROM cohort
  
  UNION ALL
  
  -- For the same cohort, flag the later weeks (1-4) in which they generated ANY event
  SELECT DISTINCT
    e.user_pseudo_id,
    DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), DATE '2018-07-02', WEEK(MONDAY)) AS weeks_since
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN cohort AS c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    -- retain only weeks 1-4 after cohort week
    AND DATE_DIFF(PARSE_DATE('%Y%m%d', e.event_date), DATE '2018-07-02', WEEK(MONDAY)) BETWEEN 1 AND 4
),
summary AS (
  -- Count distinct users per week index
  SELECT
    weeks_since,
    COUNT(DISTINCT user_pseudo_id) AS user_count
  FROM weekly_flags
  GROUP BY weeks_since
)

SELECT
  IFNULL((SELECT user_count FROM summary WHERE weeks_since = 0), 0) AS week0_new_users,
  IFNULL((SELECT user_count FROM summary WHERE weeks_since = 1), 0) AS week1_retained,
  IFNULL((SELECT user_count FROM summary WHERE weeks_since = 2), 0) AS week2_retained,
  IFNULL((SELECT user_count FROM summary WHERE weeks_since = 3), 0) AS week3_retained,
  IFNULL((SELECT user_count FROM summary WHERE weeks_since = 4), 0) AS week4_retained;