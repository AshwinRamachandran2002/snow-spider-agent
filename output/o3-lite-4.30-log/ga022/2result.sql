WITH events AS (  -- only required columns, Shanghai time applied
  SELECT
    user_pseudo_id,
    event_name,
    TIMESTAMP_MICROS(event_timestamp + 8*60*60*1000000) AS sh_ts
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '28'     -- scan 1‑28 Sep
),

cohort AS (       -- users whose first_open occurred 1‑7 Sep (Shanghai)
  SELECT DISTINCT user_pseudo_id
  FROM events
  WHERE event_name = 'first_open'
    AND DATE(sh_ts) BETWEEN '2018-09-01' AND '2018-09-07'
),

activity AS (     -- subsequent activity by cohort users in weeks 1‑3
  SELECT DISTINCT
    e.user_pseudo_id,
    DATE(e.sh_ts) AS act_date
  FROM events AS e
  JOIN cohort  USING (user_pseudo_id)
  WHERE DATE(e.sh_ts) BETWEEN '2018-09-08' AND '2018-09-28'
),

retention AS (    -- one row per retained user & week number
  SELECT
    user_pseudo_id,
    CASE
      WHEN act_date BETWEEN '2018-09-08' AND '2018-09-14' THEN 1
      WHEN act_date BETWEEN '2018-09-15' AND '2018-09-21' THEN 2
      WHEN act_date BETWEEN '2018-09-22' AND '2018-09-28' THEN 3
    END AS week_num
  FROM activity
  GROUP BY user_pseudo_id, week_num
)

SELECT
  '2018-09-01' AS cohort_start_week,
  ROUND(COUNTIF(week_num = 1) / COUNT(DISTINCT cohort.user_pseudo_id), 4) AS week1_retention_rate,
  ROUND(COUNTIF(week_num = 2) / COUNT(DISTINCT cohort.user_pseudo_id), 4) AS week2_retention_rate,
  ROUND(COUNTIF(week_num = 3) / COUNT(DISTINCT cohort.user_pseudo_id), 4) AS week3_retention_rate
FROM cohort
LEFT JOIN retention USING (user_pseudo_id);