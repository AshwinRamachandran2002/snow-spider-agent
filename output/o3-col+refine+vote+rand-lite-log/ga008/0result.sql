-- Total page views per day in Nov-2020 and average page views per purchasing user
WITH purchase_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
),
daily_views AS (
  SELECT
    event_date,               -- in YYYYMMDD format
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchase_users)
)
SELECT
  event_date,
  COUNT(*) AS total_page_views,
  ROUND(COUNT(*) / COUNT(DISTINCT user_pseudo_id), 2) AS avg_page_views_per_user
FROM daily_views
GROUP BY event_date
ORDER BY event_date;