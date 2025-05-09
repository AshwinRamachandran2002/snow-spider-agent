-- 7-day (weekly) retention for the cohort whose very first session fell in the week
-- that starts on Monday 2018-07-02.  Data observed only up to 2018-10-02.
WITH events AS (
  -- every session_start between 2018-07-02 and 2018-10-02
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    AND event_name = 'session_start'
),

first_sessions AS (
  -- the first-ever session date of each user
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM events
  GROUP BY user_pseudo_id
),

cohort AS (
  -- users whose first session falls in the Monday-based week that begins 2018-07-02
  SELECT
    user_pseudo_id
  FROM first_sessions
  WHERE DATE_TRUNC(first_session_date, WEEK(MONDAY)) = DATE '2018-07-02'
),

labeled AS (
  -- tag every subsequent session of the cohort with a week offset (0 = cohort week)
  SELECT
    e.user_pseudo_id,
    DATE_DIFF(
      DATE_TRUNC(e.event_date, WEEK(MONDAY)),
      DATE '2018-07-02',
      WEEK(MONDAY)
    ) AS week_number
  FROM events e
  JOIN cohort USING (user_pseudo_id)
  WHERE DATE_DIFF(
          DATE_TRUNC(e.event_date, WEEK(MONDAY)),
          DATE '2018-07-02',
          WEEK(MONDAY)
        ) BETWEEN 0 AND 4   -- keep weeks 0-4 only
),

retained AS (
  -- how many distinct cohort users had a session in each week
  SELECT
    week_number,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM labeled
  GROUP BY week_number
)

-- final output: week_number | new_users (week-0 size) | retained_users
SELECT
  0 AS week_number,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM cohort) AS new_users,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM cohort) AS retained_users
UNION ALL
SELECT
  week_number,
  (SELECT COUNT(DISTINCT user_pseudo_id) FROM cohort) AS new_users,
  retained_users
FROM retained
WHERE week_number BETWEEN 1 AND 4
ORDER BY week_number;