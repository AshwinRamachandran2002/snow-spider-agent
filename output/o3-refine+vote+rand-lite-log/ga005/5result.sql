/* Week‑2 retention by weekly cohort (Mon‑Sun)                    */
/* Cohort window : 09‑Jul‑2018 → 17‑Sep‑2018                      */
/* Data window   : 09‑Jul‑2018 → 02‑Oct‑2018                      */
WITH base AS (
  -- All session_start events we need
  SELECT
    PARSE_DATE('%Y%m%d', event_date)               AS event_date,
    user_pseudo_id,
    user_first_touch_timestamp
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'   -- limit tables read
    AND event_name = 'session_start'
),
cohort_users AS (
  -- Users whose first_touch day is inside the session_start -> cohort members
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(event_date, WEEK(MONDAY))             AS cohort_week_start
  FROM base
  WHERE event_date = DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
),
week2_returners AS (
  -- Same users having a session_start in week 2 (+14 … +20 days)
  SELECT DISTINCT
    cu.user_pseudo_id,
    cu.cohort_week_start
  FROM cohort_users cu
  JOIN base b
    ON b.user_pseudo_id = cu.user_pseudo_id
  WHERE
    b.event_date BETWEEN DATE_ADD(cu.cohort_week_start, INTERVAL 14 DAY)
                     AND DATE_ADD(cu.cohort_week_start, INTERVAL 20 DAY)
),
cohort_agg AS (
  SELECT
    cu.cohort_week_start,
    COUNT(DISTINCT cu.user_pseudo_id)                AS cohort_size,
    COUNT(DISTINCT wr.user_pseudo_id)                AS retained_users
  FROM cohort_users cu
  LEFT JOIN week2_returners wr
    USING (user_pseudo_id, cohort_week_start)
  GROUP BY cu.cohort_week_start
)
SELECT
  cohort_week_start AS cohort_monday,
  ROUND(SAFE_DIVIDE(retained_users, cohort_size) * 100, 4) AS week2_retention_rate
FROM cohort_agg
WHERE cohort_week_start BETWEEN '2018-07-09' AND '2018-09-17'
ORDER BY cohort_monday;