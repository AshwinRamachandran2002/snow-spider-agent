WITH cohorts AS (
  SELECT
    `user_pseudo_id`,
    DATE_TRUNC(DATE(TIMESTAMP_MICROS(MIN(`event_timestamp`))), WEEK(MONDAY)) AS `Cohort_Week_Start_Date`,
    DATE(TIMESTAMP_MICROS(MIN(`event_timestamp`))) AS `first_session_date`
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE `event_name` = 'session_start'
    AND DATE(TIMESTAMP_MICROS(`event_timestamp`)) >= '2018-07-09'
    AND DATE(TIMESTAMP_MICROS(`event_timestamp`)) <= '2018-09-23'
  GROUP BY `user_pseudo_id`
),
cohort_sizes AS (
  SELECT
    `Cohort_Week_Start_Date`,
    COUNT(DISTINCT `user_pseudo_id`) AS `users_in_cohort`
  FROM cohorts
  GROUP BY `Cohort_Week_Start_Date`
),
retention_counts AS (
  SELECT
    cohorts.`Cohort_Week_Start_Date`,
    COUNT(DISTINCT cohorts.`user_pseudo_id`) AS `retained_users`
  FROM cohorts
  JOIN `firebase-public-project.analytics_153293282.events_*` AS returns
    ON cohorts.`user_pseudo_id` = returns.`user_pseudo_id`
  WHERE returns.`event_name` = 'session_start'
    AND DATE(TIMESTAMP_MICROS(returns.`event_timestamp`)) BETWEEN DATE_ADD(cohorts.`first_session_date`, INTERVAL 8 DAY)
      AND DATE_ADD(cohorts.`first_session_date`, INTERVAL 14 DAY)
  GROUP BY cohorts.`Cohort_Week_Start_Date`
)
SELECT
  cohort_sizes.`Cohort_Week_Start_Date`,
  ROUND((IFNULL(retention_counts.`retained_users`, 0) / cohort_sizes.`users_in_cohort`) * 100, 4) AS `Retention_Rate_Percentage`
FROM cohort_sizes
LEFT JOIN retention_counts
  ON cohort_sizes.`Cohort_Week_Start_Date` = retention_counts.`Cohort_Week_Start_Date`
WHERE cohort_sizes.`Cohort_Week_Start_Date` BETWEEN DATE('2018-07-09') AND DATE('2018-09-17')
ORDER BY cohort_sizes.`Cohort_Week_Start_Date`
LIMIT 11