WITH first_sessions AS (
  -- Each user’s very first session (from 2018-07-02 onward)
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_session_ts_micros
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX >= '20180702'          -- use tables from 2 Jul 2018 forward
    AND event_name = 'session_start'
  GROUP BY
    user_pseudo_id
),
cohorts AS (
  -- Assign each user to the Monday of the week of their first session
  SELECT
    user_pseudo_id,
    DATE_TRUNC(DATE(TIMESTAMP_MICROS(first_session_ts_micros)), WEEK(MONDAY))
      AS cohort_monday,
    first_session_ts_micros
  FROM
    first_sessions
),
week4_returns AS (
  -- Users who start a new session 21-27 days after their first one
  SELECT DISTINCT
    e.user_pseudo_id
  FROM
    `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN
    cohorts AS c
  USING (user_pseudo_id)
  WHERE
    e.event_name = 'session_start'
    AND DATE_DIFF(
          DATE(TIMESTAMP_MICROS(e.event_timestamp)),
          DATE(TIMESTAMP_MICROS(c.first_session_ts_micros)),
          DAY
        ) BETWEEN 21 AND 27
)
-- Pick the cohort Monday with the highest Week-4 retention rate
SELECT
  c.cohort_monday                     -- ► answer in “YYYY-MM-DD” format ◄
FROM
  cohorts AS c
LEFT JOIN
  week4_returns AS w
ON
  c.user_pseudo_id = w.user_pseudo_id
GROUP BY
  c.cohort_monday
ORDER BY
  SAFE_DIVIDE(COUNT(DISTINCT w.user_pseudo_id),
              COUNT(DISTINCT c.user_pseudo_id)) DESC
LIMIT 1;