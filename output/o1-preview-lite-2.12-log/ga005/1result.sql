WITH
  first_sessions AS (
    SELECT
      user_pseudo_id,
      MIN(TIMESTAMP_MICROS(event_timestamp)) AS first_session_timestamp
    FROM
      `firebase-public-project.analytics_153293282.events_*`
    WHERE
      event_name = 'session_start'
      AND `_TABLE_SUFFIX` BETWEEN '20180709' AND '20181002'
    GROUP BY
      user_pseudo_id
    HAVING
      first_session_timestamp >= TIMESTAMP('2018-07-09')
  ),
  cohort_data AS (
    SELECT
      user_pseudo_id,
      DATE_TRUNC(DATE(first_session_timestamp), WEEK(MONDAY)) AS cohort_week_start_date
    FROM
      first_sessions
    WHERE
      DATE_TRUNC(DATE(first_session_timestamp), WEEK(MONDAY)) <= DATE('2018-09-17')
  ),
  cohort_sizes AS (
    SELECT
      cohort_week_start_date,
      COUNT(DISTINCT user_pseudo_id) AS total_users
    FROM
      cohort_data
    GROUP BY
      cohort_week_start_date
  ),
  week2_events AS (
    SELECT
      DISTINCT cd.user_pseudo_id,
      cd.cohort_week_start_date
    FROM
      cohort_data cd
    INNER JOIN
      `firebase-public-project.analytics_153293282.events_*` e
    ON
      cd.user_pseudo_id = e.user_pseudo_id
      AND DATE(TIMESTAMP_MICROS(e.event_timestamp)) BETWEEN DATE_ADD(cd.cohort_week_start_date, INTERVAL 7 DAY)
      AND DATE_SUB(DATE_ADD(cd.cohort_week_start_date, INTERVAL 14 DAY), INTERVAL 1 DAY)
    WHERE
      e.event_name = 'session_start'
      AND e.`_TABLE_SUFFIX` BETWEEN FORMAT_DATE('%Y%m%d', DATE_ADD(cd.cohort_week_start_date, INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', DATE_SUB(DATE_ADD(cd.cohort_week_start_date, INTERVAL 14 DAY), INTERVAL 1 DAY))
  ),
  retention_counts AS (
    SELECT
      cohort_week_start_date,
      COUNT(DISTINCT user_pseudo_id) AS retained_users
    FROM
      week2_events
    GROUP BY
      cohort_week_start_date
  )
SELECT
  DATE(cohort_week_start_date) AS Cohort_Week_Start_Date,
  ROUND(COALESCE(retained_users, 0) / total_users * 100, 4) AS Retention_Rate_Percentage
FROM
  cohort_sizes cs
LEFT JOIN
  retention_counts rc
USING
  (cohort_week_start_date)
ORDER BY
  Cohort_Week_Start_Date;