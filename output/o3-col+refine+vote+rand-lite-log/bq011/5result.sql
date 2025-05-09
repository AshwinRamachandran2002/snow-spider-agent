-- Distinct pseudo-users with positive engagement in the 7-day window (2021-01-01 – 2021-01-07),
-- but none in the 2-day window (2021-01-06 – 2021-01-07).
WITH users_7d AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'      -- 7-day window
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
),
users_2d AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'      -- 2-day window
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
)
SELECT
  COUNT(*) AS users_7d_no_2d
FROM users_7d
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM users_2d);