WITH
-- 7‑day window (2021‑01‑01 to 2021‑01‑07)
seven_day_raw AS (
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210101`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210103`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210104`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210105`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210106`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210107`
),
seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM seven_day_raw,
       UNNEST(event_params) AS ep
  WHERE event_name = 'user_engagement'
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
),

-- 2‑day window (2021‑01‑06 to 2021‑01‑07)
two_day_raw AS (
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210106`
  UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210107`
),
two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM two_day_raw,
       UNNEST(event_params) AS ep
  WHERE event_name = 'user_engagement'
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
)

SELECT COUNT(*) AS distinct_pseudo_users
FROM seven_day
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day);