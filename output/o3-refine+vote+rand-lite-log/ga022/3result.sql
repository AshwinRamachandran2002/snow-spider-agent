/* Weekly retention for users whose very first `first_open`
   happened between 01‑Sep‑2018 00:00 and 07‑Sep‑2018 23:59
   (Asia/Shanghai).  Retention shown for weeks 1, 2 and 3. */

WITH cohort AS (
  SELECT
    user_pseudo_id,
    MIN(TIMESTAMP_MICROS(event_timestamp) + INTERVAL 8 HOUR) AS cohort_ts   -- Shanghai TZ
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

events AS (
  SELECT
    e.user_pseudo_id,
    TIMESTAMP_MICROS(e.event_timestamp) + INTERVAL 8 HOUR AS event_ts_sh     -- Shanghai TZ
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN cohort c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
),

user_weeks AS (
  SELECT DISTINCT
    c.user_pseudo_id,
    FLOOR(
      DATE_DIFF(DATE(event_ts_sh), DATE(c.cohort_ts), DAY) / 7
    ) AS week_index                          -- 1 = week‑1, 2 = week‑2, 3 = week‑3
  FROM cohort c
  JOIN events e
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE DATE_DIFF(DATE(event_ts_sh), DATE(c.cohort_ts), DAY) BETWEEN 1 AND 27
)

SELECT
  COUNT(DISTINCT c.user_pseudo_id) AS cohort_size,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT IF(uw.week_index = 1, c.user_pseudo_id, NULL)),
      COUNT(DISTINCT c.user_pseudo_id)
    ), 4) AS week1_retention,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT IF(uw.week_index = 2, c.user_pseudo_id, NULL)),
      COUNT(DISTINCT c.user_pseudo_id)
    ), 4) AS week2_retention,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT IF(uw.week_index = 3, c.user_pseudo_id, NULL)),
      COUNT(DISTINCT c.user_pseudo_id)
    ), 4) AS week3_retention
FROM cohort c
LEFT JOIN user_weeks uw
  ON c.user_pseudo_id = uw.user_pseudo_id;