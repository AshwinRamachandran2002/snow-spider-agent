-- Total & average page-views per day in Nov-2020
-- (restricted to users who made ≥1 purchase during Nov-2020)

WITH purchase_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
),
daily_counts AS (
  SELECT
    event_date,
    COUNT(*)                         AS total_page_views,
    COUNT(DISTINCT user_pseudo_id)   AS users_viewing
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchase_users)
  GROUP BY event_date
)
SELECT
  event_date,
  total_page_views,
  SAFE_DIVIDE(total_page_views, users_viewing) AS avg_page_views_per_user
FROM daily_counts
ORDER BY event_date;