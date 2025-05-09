/*  Weekly cohorts (Mon‑Sun) and their Week‑2 (days 14‑20) retention
    – cohorts starting 09‑Jul‑2018 through 17‑Sep‑2018                */

WITH mondays AS (                         -- list of cohort start dates
  SELECT DATE '2018-07-09' + INTERVAL wk WEEK AS cohort_date
  FROM   UNNEST(GENERATE_ARRAY(0, 10)) AS wk          -- 11 Mondays
),

cohort_users AS (                         -- users whose very first session is in that week
  SELECT
    m.cohort_date,
    e.user_pseudo_id
  FROM   mondays AS m
  JOIN   `firebase-public-project.analytics_153293282.events_*` AS e
  ON     TRUE
  WHERE  e.event_name = 'session_start'
    AND  PARSE_DATE('%Y%m%d', e.event_date)
          BETWEEN m.cohort_date                     -- Mon‑Sun window
              AND m.cohort_date + INTERVAL 6 DAY
    AND  e.event_date = FORMAT_DATE(                -- event day == first‑touch day
           '%Y%m%d',
           DATE(TIMESTAMP_MICROS(e.user_first_touch_timestamp))
         )
    AND  _TABLE_SUFFIX BETWEEN                     -- prune partitions
          FORMAT_DATE('%Y%m%d', m.cohort_date)
      AND FORMAT_DATE('%Y%m%d', m.cohort_date + INTERVAL 6 DAY)
  GROUP BY m.cohort_date, e.user_pseudo_id
),

week2_returners AS (                      -- same users who come back in days 14‑20
  SELECT DISTINCT
    cu.cohort_date,
    cu.user_pseudo_id
  FROM   cohort_users AS cu
  JOIN   `firebase-public-project.analytics_153293282.events_*` AS e
    ON   cu.user_pseudo_id = e.user_pseudo_id
  WHERE  e.event_name = 'session_start'
    AND  PARSE_DATE('%Y%m%d', e.event_date)
          BETWEEN cu.cohort_date + INTERVAL 14 DAY
              AND cu.cohort_date + INTERVAL 20 DAY
    AND  _TABLE_SUFFIX BETWEEN
          FORMAT_DATE('%Y%m%d', cu.cohort_date + INTERVAL 14 DAY)
      AND FORMAT_DATE('%Y%m%d', cu.cohort_date + INTERVAL 20 DAY)
)

SELECT
  FORMAT_DATE('%Y-%m-%d', c.cohort_date)            AS cohort_week,
  COUNT(DISTINCT c.user_pseudo_id)                  AS cohort_size,
  COUNT(DISTINCT r.user_pseudo_id)                  AS week2_active,
  ROUND(
    SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id)
    ) * 100,                                        -- percentage
    4
  ) AS week2_retention_rate_pct
FROM   cohort_users      AS c
LEFT JOIN week2_returners AS r
       ON  c.cohort_date = r.cohort_date
       AND c.user_pseudo_id = r.user_pseudo_id
GROUP  BY c.cohort_date
ORDER  BY c.cohort_date;