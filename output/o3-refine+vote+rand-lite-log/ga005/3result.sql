/*-----------------------------------------------------------
Weekly (Monday‑based) cohort – Week‑2 retention
Cohort window     : 09‑Jul‑2018 … 17‑Sep‑2018  (last cohort
                    that can have a full 2‑week look‑ahead)
Event data window : 09‑Jul‑2018 … 02‑Oct‑2018
-----------------------------------------------------------*/
WITH base AS (
  SELECT
    user_pseudo_id,
    event_name,
    /* event_date comes as STRING YYYYMMDD → convert to DATE  */
    DATE(PARSE_DATE('%Y%m%d', event_date))                        AS event_dt,
    /* user_first_touch_timestamp is in micro‑seconds epoch      */
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))            AS first_touch_dt
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'               -- scan only what we need
),

/* All session_start events in the period ------------------- */
sessions AS (
  SELECT
    user_pseudo_id,
    event_dt
  FROM base
  WHERE event_name = 'session_start'
),

/* Users whose very FIRST session_start occurs in this period
   (event date = first‑touch date) --------------------------- */
new_users AS (
  SELECT DISTINCT
    user_pseudo_id,
    event_dt                                                   AS day0_dt,
    /* Monday that starts the cohort week                      */
    DATE_TRUNC(event_dt, WEEK(MONDAY))                         AS cohort_start
  FROM base
  WHERE
    event_name        = 'session_start'
    AND event_dt      = first_touch_dt                         -- true new users
    AND DATE_TRUNC(event_dt, WEEK(MONDAY))
          BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'      -- cohorts to analyse
)

/* Week‑2 return (days 14‑20, i.e. the 3rd Monday‑Sunday span) */
SELECT
  cohort_start,
  COUNT(DISTINCT nu.user_pseudo_id)                                        AS cohort_size,
  COUNT(DISTINCT rs.user_pseudo_id)                                        AS retained_users,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT rs.user_pseudo_id),
                          COUNT(DISTINCT nu.user_pseudo_id)), 2) || '%'    AS week2_retention_rate
FROM
  new_users AS nu
LEFT JOIN
  sessions  AS rs
ON  rs.user_pseudo_id = nu.user_pseudo_id
AND rs.event_dt BETWEEN DATE_ADD(nu.cohort_start, INTERVAL 14 DAY)
                    AND DATE_ADD(nu.cohort_start, INTERVAL 20 DAY)
GROUP BY
  cohort_start
ORDER BY
  cohort_start;