-- Weekly retention (weeks 1‑3) for users whose first_open happened
-- during 1‑7 Sep 2018 in Asia/Shanghai time
WITH base AS (                                  -- September 2018 events
  SELECT
    user_pseudo_id,
    event_name,
    DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai') AS event_date_sh
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
),
cohort AS (                                    -- cohort = first_open 1‑7 Sep 2018
  SELECT
    user_pseudo_id,
    MIN(event_date_sh) AS cohort_date
  FROM base
  WHERE event_name = 'first_open'
    AND event_date_sh BETWEEN DATE '2018-09-01' AND DATE '2018-09-07'
  GROUP BY user_pseudo_id
),
timeline AS (                                  -- all September events of cohort
  SELECT
    b.user_pseudo_id,
    DATE_DIFF(b.event_date_sh, c.cohort_date, DAY) AS day_diff
  FROM base AS b
  JOIN cohort AS c USING (user_pseudo_id)
  WHERE b.event_date_sh BETWEEN DATE '2018-09-01' AND DATE '2018-09-30'
),
buckets AS (                                   -- first week bucket reached
  SELECT DISTINCT
    user_pseudo_id,
    CASE
      WHEN day_diff BETWEEN  7 AND 13 THEN 1   -- Week 1
      WHEN day_diff BETWEEN 14 AND 20 THEN 2   -- Week 2
      WHEN day_diff BETWEEN 21 AND 27 THEN 3   -- Week 3
    END AS week_no
  FROM timeline
  WHERE day_diff BETWEEN 7 AND 27
),
retained AS (                                  -- users retained per week
  SELECT
    week_no,
    COUNT(DISTINCT user_pseudo_id) AS users_retained
  FROM buckets
  GROUP BY week_no
),
cohort_size AS (                               -- cohort size
  SELECT COUNT(*) AS size FROM cohort
)
SELECT
  cs.size                                                         AS cohort_size,
  SAFE_DIVIDE(r1.users_retained, cs.size)                         AS week1_rate,
  SAFE_DIVIDE(r2.users_retained, cs.size)                         AS week2_rate,
  SAFE_DIVIDE(r3.users_retained, cs.size)                         AS week3_rate
FROM cohort_size            AS cs
LEFT JOIN retained AS r1 ON r1.week_no = 1
LEFT JOIN retained AS r2 ON r2.week_no = 2
LEFT JOIN retained AS r3 ON r3.week_no = 3
;