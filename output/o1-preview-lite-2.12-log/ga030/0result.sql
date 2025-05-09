WITH user_first_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_session_date
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'
    AND event_name = 'session_start'
  GROUP BY
    user_pseudo_id
),

user_cohorts AS (
  SELECT
    user_pseudo_id,
    first_session_date,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS first_session_week
  FROM user_first_sessions
),

user_events AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_date
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180702' AND '20181031'
),

user_retention AS (
  SELECT
    uc.user_pseudo_id,
    uc.first_session_week,
    MAX(CASE WHEN ue.event_date BETWEEN DATE_ADD(uc.first_session_week, INTERVAL 21 DAY) AND DATE_ADD(uc.first_session_week, INTERVAL 27 DAY) THEN 1 ELSE 0 END) AS returned_in_fourth_week
  FROM
    user_cohorts uc
  LEFT JOIN
    user_events ue
  ON
    uc.user_pseudo_id = ue.user_pseudo_id
  GROUP BY
    uc.user_pseudo_id, uc.first_session_week
),

cohort_retention AS (
  SELECT
    first_session_week,
    COUNT(*) AS total_users,
    SUM(returned_in_fourth_week) AS users_returned_in_fourth_week,
    SAFE_DIVIDE(SUM(returned_in_fourth_week), COUNT(*)) AS retention_rate
  FROM
    user_retention
  GROUP BY
    first_session_week
)

SELECT
  FORMAT_DATE('%Y-%m-%d', first_session_week) AS cohort_week_start
FROM
  cohort_retention
ORDER BY
  retention_rate DESC, first_session_week
LIMIT 1