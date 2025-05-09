-- Week-2 retention for Monday cohorts between 2018-07-09 and 2018-09-17
WITH base AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt,
    PARSE_DATE(
      '%Y%m%d',
      FORMAT_TIMESTAMP('%Y%m%d', TIMESTAMP_MICROS(user_first_touch_timestamp))
    )                                  AS first_touch_dt
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
        _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'   -- data range present
    AND event_name = 'session_start'                      -- only sessions
),
-- users whose first session happens in their first-touch week
cohort_users AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(first_touch_dt, WEEK(MONDAY)) AS cohort_week_start
  FROM base
  WHERE event_dt = first_touch_dt
),
-- every distinct session date for each user
session_dates AS (
  SELECT DISTINCT
    user_pseudo_id,
    event_dt
  FROM base
)
SELECT
  cu.cohort_week_start,
  ROUND(
    100 * SAFE_DIVIDE(
      COUNT(DISTINCT IF(
        sd.event_dt BETWEEN cu.cohort_week_start + 14
                        AND     cu.cohort_week_start + 20,
        cu.user_pseudo_id,
        NULL
      )),
      COUNT(DISTINCT cu.user_pseudo_id)
    ),
    2
  ) AS week2_retention_rate_percent
FROM
  cohort_users  AS cu
LEFT JOIN
  session_dates AS sd
USING (user_pseudo_id)
WHERE
  cu.cohort_week_start BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
GROUP BY
  cu.cohort_week_start
ORDER BY
  cu.cohort_week_start;