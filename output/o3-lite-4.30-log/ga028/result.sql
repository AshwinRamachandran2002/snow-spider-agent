/* 7‑day, Monday‑based retention for users whose very FIRST session_start
   fell in the week Mon‑Sun 02‑Jul‑2018 → 08‑Jul‑2018.
   Only events up to (and including) 02‑Oct‑2018 are considered.             */

WITH first_sessions AS (          -- earliest session_start we see for each user
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_session_date
  FROM
    `firebase-public-project.analytics_153293282.events_*`
  WHERE
    _TABLE_SUFFIX <= '20181002'          -- scan only data that can matter
    AND event_name = 'session_start'
  GROUP BY
    user_pseudo_id
),

cohort AS (                      -- keep users whose first‑ever session was in the target week
  SELECT
    user_pseudo_id
  FROM
    first_sessions
  WHERE
    first_session_date BETWEEN '20180702' AND '20180708'
),

events_in_scope AS (             -- one row per user‑week (Week 0 … Week 4)
  SELECT DISTINCT
    e.user_pseudo_id,
    DATE_DIFF(
      DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
      DATE '2018-07-02',
      WEEK(MONDAY)
    ) AS week_bucket
  FROM
    `firebase-public-project.analytics_153293282.events_*` e
  JOIN
    cohort c
  ON
    e.user_pseudo_id = c.user_pseudo_id
  WHERE
    e._TABLE_SUFFIX BETWEEN '20180702' AND '20181002'
    AND DATE_DIFF(
          DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
          DATE '2018-07-02',
          WEEK(MONDAY)
        ) BETWEEN 0 AND 4
),

retention AS (                   -- number of retained users in each bucket
  SELECT
    week_bucket,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM
    events_in_scope
  GROUP BY
    week_bucket
),

week_list AS (                   -- ensure rows for buckets 0‑4 even if empty
  SELECT 0 AS week_bucket UNION ALL
  SELECT 1 UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4
)

SELECT
  wl.week_bucket                     AS week,
  (SELECT COUNT(*) FROM cohort)      AS cohort_size,
  COALESCE(r.retained_users, 0)      AS retained_users
FROM
  week_list wl
LEFT JOIN
  retention r
ON
  wl.week_bucket = r.week_bucket
ORDER BY
  week;