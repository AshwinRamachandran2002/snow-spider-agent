-- Weekly cohort analysis (Week‑2 retention) on GA4 public gaming data
WITH sessions AS (   -- keep only session_start events we need
  SELECT
    PARSE_DATE('%Y%m%d', event_date)                           AS event_date,
    user_pseudo_id,
    user_first_touch_timestamp
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20180709' AND '20181003'            -- scan only necessary daily tables
    AND event_name = 'session_start'
),

-- users whose very first session happens the same day as their first touch
new_users AS (
  SELECT
    user_pseudo_id,
    MIN(event_date)                                            AS first_event_date
  FROM
    sessions
  WHERE
    event_date = DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
  GROUP BY
    user_pseudo_id
),

-- map new users to their cohort week (weeks start on Monday)
cohort_users AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_event_date, WEEK(MONDAY))                 AS cohort_week_start
  FROM
    new_users
  WHERE
    first_event_date BETWEEN '2018-07-09' AND '2018-09-17'     -- cohorts we can measure 2‑week retention for
),

-- any session the user has in the 2‑week‑after window (days 14‑20)
week2_activity AS (
  SELECT DISTINCT
    s.user_pseudo_id
  FROM
    sessions  s
  JOIN
    cohort_users c
  ON  s.user_pseudo_id = c.user_pseudo_id
  WHERE
    s.event_date BETWEEN DATE_ADD(c.cohort_week_start, INTERVAL 14 DAY)
                     AND DATE_ADD(c.cohort_week_start, INTERVAL 20 DAY)
),

-- aggregate cohort sizes and retained users
retention AS (
  SELECT
    c.cohort_week_start,
    COUNT(DISTINCT c.user_pseudo_id)              AS cohort_size,
    COUNT(DISTINCT w.user_pseudo_id)              AS week2_users
  FROM
    cohort_users  c
  LEFT JOIN
    week2_activity w
  ON  c.user_pseudo_id = w.user_pseudo_id
  GROUP BY
    c.cohort_week_start
)

SELECT
  cohort_week_start                        AS cohort_start_monday,
  ROUND(SAFE_DIVIDE(week2_users, cohort_size) * 100, 4)  AS week2_retention_rate_percent
FROM
  retention
ORDER BY
  cohort_week_start;