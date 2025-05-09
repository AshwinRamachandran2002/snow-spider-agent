WITH nov_events AS (
  SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201102`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201103`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201104`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201105`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201106`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201107`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201108`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201109`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201110`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201111`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201112`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201113`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201114`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201115`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201116`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201118`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201119`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201120`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201121`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201122`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201123`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201124`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201125`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201126`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201127`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201128`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201129`
  UNION ALL SELECT event_date, event_name, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
),
purchasers AS (
  SELECT DISTINCT user_pseudo_id
  FROM nov_events
  WHERE event_name = 'purchase'
),
daily_views AS (
  SELECT
    event_date,
    user_pseudo_id
  FROM nov_events
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchasers)
)
SELECT
  event_date AS date,
  COUNT(*) AS total_page_views,
  ROUND(SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id)), 4) AS avg_page_views_per_user
FROM daily_views
GROUP BY event_date
ORDER BY event_date;