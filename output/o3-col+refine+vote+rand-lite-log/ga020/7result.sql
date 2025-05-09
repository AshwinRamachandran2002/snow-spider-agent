WITH cohort AS (
  -- Users whose FIRST Quick-Play event happened between Aug-01 and Aug-15-2018
  SELECT
    event_name,
    user_pseudo_id,
    MIN(TIMESTAMP_MICROS(event_timestamp)) AS cohort_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY event_name, user_pseudo_id
),
sessions AS (
  -- All session_start events we will use to check retention (up to Aug-29-2018)
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(event_timestamp) AS session_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'
    AND event_name = 'session_start'
)
SELECT
  c.event_name,
  COUNT(DISTINCT c.user_pseudo_id) AS cohort_users,
  COUNT(DISTINCT IF(
        DATE_DIFF(DATE(s.session_ts), DATE(c.cohort_ts), DAY) BETWEEN 8 AND 14,
        c.user_pseudo_id,
        NULL))                     AS retained_users,
  SAFE_DIVIDE(
        COUNT(DISTINCT IF(
              DATE_DIFF(DATE(s.session_ts), DATE(c.cohort_ts), DAY) BETWEEN 8 AND 14,
              c.user_pseudo_id,
              NULL)),
        COUNT(DISTINCT c.user_pseudo_id))              AS week2_retention
FROM cohort AS c
LEFT JOIN sessions AS s
ON s.user_pseudo_id = c.user_pseudo_id
GROUP BY c.event_name
ORDER BY week2_retention ASC
LIMIT 1;