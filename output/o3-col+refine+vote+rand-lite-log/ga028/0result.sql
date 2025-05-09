-- 7-day (weekly) retention for the cohort whose FIRST session_start 
-- occurred during Monday-based Week 0:  Mon-02-Jul-2018  → Sun-08-Jul-2018.
-- We look at Weeks 0-4 and only use data up to 02-Oct-2018.

WITH first_sessions AS (        -- each user’s very first session_start
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180601' AND '20181002'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),

cohort AS (                     -- users whose first session fell in Week-0
  SELECT user_pseudo_id
  FROM first_sessions
  WHERE first_session_date BETWEEN '20180702' AND '20180708'
),

events_tagged AS (              -- every event of a cohort user, tagged by week index
  SELECT
    e.user_pseudo_id,
    DATE_DIFF( PARSE_DATE('%Y%m%d', e.event_date),
               DATE '2018-07-02',
               WEEK(MONDAY) )                      AS week_index
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN cohort c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e._TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    AND DATE_DIFF( PARSE_DATE('%Y%m%d', e.event_date),
                   DATE '2018-07-02',
                   WEEK(MONDAY) ) BETWEEN 0 AND 4  -- Weeks 0-4 only
  GROUP BY e.user_pseudo_id, week_index            -- collapse to 1 row per user*week
),

weekly_retention AS (           -- distinct users present in each week
  SELECT
    week_index,
    COUNT(DISTINCT user_pseudo_id) AS users
  FROM events_tagged
  GROUP BY week_index
)

-- final retention table -----------------------------------------------------
SELECT
  0 AS week_index,                          -- Week-0 (cohort size)
  (SELECT COUNT(*) FROM cohort) AS users
UNION ALL
SELECT                                       -- Weeks 1-4 retained users
  week_index,
  users
FROM weekly_retention
WHERE week_index <> 0
ORDER BY week_index;