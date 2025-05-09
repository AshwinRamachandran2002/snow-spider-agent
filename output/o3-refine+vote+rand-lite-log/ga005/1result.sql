WITH sessions AS (
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date)                            AS event_dt,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))          AS first_touch_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181003'         -- limit to needed dates
    AND event_name = 'session_start'
),

/* ---------- build the weekly cohorts (week starts on Monday) ---------- */
cohort_users AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(event_dt, WEEK(MONDAY)) AS cohort_week_start
  FROM sessions
  WHERE event_dt = first_touch_dt                              -- user’s first day = new user
    AND DATE_TRUNC(event_dt, WEEK(MONDAY))                     -- cohorts we can evaluate
        BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),

/* ---------- identify users who return exactly two weeks later ---------- */
week2_retained AS (
  SELECT DISTINCT
    cu.user_pseudo_id,
    cu.cohort_week_start
  FROM cohort_users cu
  JOIN sessions s
    ON s.user_pseudo_id = cu.user_pseudo_id
  WHERE DATE_DIFF(
          DATE_TRUNC(s.event_dt, WEEK(MONDAY)),                -- week of this session
          cu.cohort_week_start,                                -- cohort’s week
          WEEK(MONDAY)
        ) = 2                                                  -- exactly 2 weeks after
)

/* ---------- aggregate: size & week‑2 retention per cohort ---------- */
SELECT
  cu.cohort_week_start                                                AS cohort_start_date,
  COUNT(DISTINCT cu.user_pseudo_id)                                   AS cohort_size,
  COUNT(DISTINCT wr.user_pseudo_id)                                   AS week2_retained_users,
  ROUND(100 *
        COUNT(DISTINCT wr.user_pseudo_id) /
        COUNT(DISTINCT cu.user_pseudo_id), 2)                         AS week2_retention_rate_pct
FROM cohort_users cu
LEFT JOIN week2_retained wr
       ON wr.user_pseudo_id = cu.user_pseudo_id
GROUP BY cu.cohort_week_start
ORDER BY cu.cohort_week_start;