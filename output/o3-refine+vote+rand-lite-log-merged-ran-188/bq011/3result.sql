-- Distinct pseudo‑users with positive engagement in the 7‑day window
-- (2021‑01‑01 – 2021‑01‑07) but none in the last 2‑day window
-- (2021‑01‑06 – 2021‑01‑07).

WITH engagement AS (
  SELECT
    user_pseudo_id,
    event_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  CROSS JOIN UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0          -- positive engagement time
),

seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210101' AND '20210107'
),

two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210106' AND '20210107'
)

SELECT COUNT(*) AS distinct_users
FROM seven_day
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day);