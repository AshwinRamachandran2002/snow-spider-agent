-- distinct pseudo‑users who had positive engagement time in the
-- 7‑day window (2021‑01‑01 … 2021‑01‑07 23:59:59) but none in the
-- last 2‑day window (2021‑01‑06 … 2021‑01‑07 23:59:59)

WITH engagement AS (
  SELECT
    user_pseudo_id,
    event_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  -- only the tables we need
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND event_name = 'user_engagement'
    -- positive engagement time
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec' 
            AND ep.value.int_value > 0
    )
),

-- users with any positive engagement in the 7‑day window
users_7d AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210101' AND '20210107'
),

-- users with any positive engagement in the last 2‑day window
users_2d AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210106' AND '20210107'
)

SELECT COUNT(*) AS distinct_users
FROM users_7d
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM users_2d);