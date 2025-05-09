WITH
-- cohort: users whose first_open (earliest) occurred 1–7 Sep 2018 (Asia/Shanghai)
cohort AS (
  SELECT
    user_pseudo_id,
    MIN(DATETIME(TIMESTAMP_MICROS(event_timestamp),'Asia/Shanghai')) AS first_open_ts_sh
  FROM (
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180901` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180902` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180903` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180904` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180905` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180906` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180907`
  )
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
  HAVING DATE(first_open_ts_sh) BETWEEN '2018-09-01' AND '2018-09-07'
),
-- returns: first‑week‑plus events for those users (session_start only)
returns AS (
  SELECT
    c.user_pseudo_id,
    FLOOR(
      DATE_DIFF(
        DATE(TIMESTAMP_MICROS(e.event_timestamp),'Asia/Shanghai'),
        DATE(c.first_open_ts_sh),
        DAY) / 7)                                                    AS week_index
  FROM (
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180908` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180909` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180910` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180911` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180912` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180913` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180914` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180915` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180916` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180917` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180918` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180919` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180920` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180921` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180922` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180923` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180924` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180925` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180926` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180927` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180928` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180929` UNION ALL
    SELECT user_pseudo_id,event_timestamp,event_name FROM `firebase-public-project.analytics_153293282.events_20180930`
  ) AS e
  JOIN cohort AS c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE e.event_name = 'session_start'
    AND DATE_DIFF(DATE(TIMESTAMP_MICROS(e.event_timestamp),'Asia/Shanghai'),
                  DATE(c.first_open_ts_sh), DAY) >= 7
    AND FLOOR(
          DATE_DIFF(
            DATE(TIMESTAMP_MICROS(e.event_timestamp),'Asia/Shanghai'),
            DATE(c.first_open_ts_sh),
            DAY) / 7) IN (1,2,3)
),
-- consolidate per user
per_user AS (
  SELECT
    c.user_pseudo_id,
    MAX(IF(r.week_index = 1,1,0)) AS w1,
    MAX(IF(r.week_index = 2,1,0)) AS w2,
    MAX(IF(r.week_index = 3,1,0)) AS w3
  FROM cohort AS c
  LEFT JOIN returns AS r
    ON c.user_pseudo_id = r.user_pseudo_id
  GROUP BY c.user_pseudo_id
)
SELECT
  '2018-09-01_to_2018-09-07'                                           AS cohort_start_week,
  ROUND(SAFE_DIVIDE(SUM(w1), COUNT(*)),4)                             AS week1_retention_rate,
  ROUND(SAFE_DIVIDE(SUM(w2), COUNT(*)),4)                             AS week2_retention_rate,
  ROUND(SAFE_DIVIDE(SUM(w3), COUNT(*)),4)                             AS week3_retention_rate
FROM per_user;