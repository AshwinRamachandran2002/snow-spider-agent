/* 7-day (weekly) retention for users whose very first session occurred
   during the Monday-based week that starts on 2018-07-02 (Mon-Sun).

   Week-index definition
   ---------------------
   Week 0 : 2018-07-02 … 2018-07-08
   Week 1 : 2018-07-09 … 2018-07-15
   Week 2 : 2018-07-16 … 2018-07-22
   Week 3 : 2018-07-23 … 2018-07-29
   Week 4 : 2018-07-30 … 2018-08-05

   Only events up to (and including) 2018-10-02 are consulted.
*/
WITH first_sessions AS (
  -- Each user’s global first session date
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),
cohort AS (
  -- Users whose first-ever session falls inside 2018-07-02 … 2018-07-08
  SELECT user_pseudo_id
  FROM first_sessions
  WHERE first_session_date BETWEEN DATE '2018-07-02' AND DATE '2018-07-08'
),
activity_weeks AS (
  -- Every Monday-based week in which a cohort user is active (<= 2018-10-02)
  SELECT
    c.user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)) AS activity_week
  FROM cohort AS c
  JOIN `firebase-public-project.analytics_153293282.events_*` AS e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e._TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
),
indexed_weeks AS (
  -- Map each user–week pair to a week_index relative to 2018-07-02
  SELECT
    user_pseudo_id,
    DIV(DATE_DIFF(activity_week, DATE '2018-07-02', DAY), 7) AS week_index
  FROM activity_weeks
  WHERE activity_week BETWEEN DATE '2018-07-02'    -- Week 0 start
                         AND DATE '2018-08-06'    -- Week 4 end (Mon of next week)
)
SELECT
  COUNT(DISTINCT IF(week_index = 0, user_pseudo_id, NULL)) AS week0_new_users,
  COUNT(DISTINCT IF(week_index = 1, user_pseudo_id, NULL)) AS week1_retained,
  COUNT(DISTINCT IF(week_index = 2, user_pseudo_id, NULL)) AS week2_retained,
  COUNT(DISTINCT IF(week_index = 3, user_pseudo_id, NULL)) AS week3_retained,
  COUNT(DISTINCT IF(week_index = 4, user_pseudo_id, NULL)) AS week4_retained
FROM indexed_weeks
WHERE week_index BETWEEN 0 AND 4;