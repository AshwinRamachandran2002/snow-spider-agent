-- 7-day retention (Weeks 0-4) for users whose first session fell in the week
-- that starts on Monday 2018-07-02.  Events considered through 2018-10-02.

WITH first_sessions AS (   -- first time each user ever fired session_start
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),

cohort AS (                -- users whose first session fell in Week-0
  SELECT user_pseudo_id
  FROM   first_sessions
  WHERE  first_dt BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),

cohort_events AS (         -- all later session_start events for those users
  SELECT
    c.user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)) AS wk_start
  FROM   `firebase-public-project.analytics_153293282.events_*` e
  JOIN   cohort AS c
         ON c.user_pseudo_id = e.user_pseudo_id
  WHERE  e.event_name = 'session_start'
    AND  _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
)

SELECT
  COUNT(DISTINCT IF(wk_start = DATE '2018-07-02', user_pseudo_id, NULL)) AS week0_new_users,
  COUNT(DISTINCT IF(wk_start = DATE '2018-07-09', user_pseudo_id, NULL)) AS week1_retained_users,
  COUNT(DISTINCT IF(wk_start = DATE '2018-07-16', user_pseudo_id, NULL)) AS week2_retained_users,
  COUNT(DISTINCT IF(wk_start = DATE '2018-07-23', user_pseudo_id, NULL)) AS week3_retained_users,
  COUNT(DISTINCT IF(wk_start = DATE '2018-07-30', user_pseudo_id, NULL)) AS week4_retained_users
FROM cohort_events;