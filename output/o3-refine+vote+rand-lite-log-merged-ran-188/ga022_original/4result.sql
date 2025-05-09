/* Weekly retention (week 1/2/3) for users whose first_open happened
   in Shanghai time during 1 – 7 Sep 2018 */

WITH cohort AS (                                       -- step 1 : build cohort
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_open_ts              -- first_open in µs (UTC)
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180831' AND '20180907'       -- tables that can contain 1–7 Sep (+08)
    AND event_name = 'first_open'
    AND DATE(TIMESTAMP_MICROS(event_timestamp), 'Asia/Shanghai')
        BETWEEN '2018-09-01' AND '2018-09-07'                 -- Shanghai calendar
  GROUP BY user_pseudo_id
),

events_with_week AS (                                 -- step 2 : attach every later event
  SELECT
    e.user_pseudo_id,
    FLOOR(                                             -- whole‑week index since open
      DATE_DIFF(
        DATE(TIMESTAMP_MICROS(e.event_timestamp),'Asia/Shanghai'),
        DATE(TIMESTAMP_MICROS(c.first_open_ts) ,'Asia/Shanghai'),
        DAY) / 7) AS week_index                        -- 0 = week of open, 1 = next week …
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN cohort c
    ON e.user_pseudo_id = c.user_pseudo_id
  WHERE _TABLE_SUFFIX BETWEEN '20180831' AND '20180928'       -- cover weeks 0‑3
),

retained AS (                                         -- step 3 : users that came back each week
  SELECT
    week_index,
    COUNT(DISTINCT user_pseudo_id) AS retained_users
  FROM events_with_week
  WHERE week_index BETWEEN 1 AND 3                           -- we need week 1/2/3 only
  GROUP BY week_index
),

cohort_size AS (SELECT COUNT(*) AS total_users FROM cohort)   -- step 4 : cohort size
SELECT
  cs.total_users                                              AS cohort_size,
  ROUND(SAFE_DIVIDE(MAX(IF(r.week_index = 1, r.retained_users, NULL)), cs.total_users), 4) AS week1_retention,
  ROUND(SAFE_DIVIDE(MAX(IF(r.week_index = 2, r.retained_users, NULL)), cs.total_users), 4) AS week2_retention,
  ROUND(SAFE_DIVIDE(MAX(IF(r.week_index = 3, r.retained_users, NULL)), cs.total_users), 4) AS week3_retention
FROM cohort_size cs
LEFT JOIN retained r ON TRUE
GROUP BY cs.total_users;