-- Daily page-views (and per-user average) for November-2020
-- restricted to users who completed at least one purchase in November-2020
WITH nov_purchasers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
),

daily_pageviews AS (
  SELECT
    event_date,
    COUNT(*)                         AS total_page_views,
    COUNT(DISTINCT user_pseudo_id)   AS users_on_day
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM nov_purchasers)
  GROUP BY event_date
)

SELECT
  event_date,
  total_page_views,
  users_on_day,
  ROUND(total_page_views / users_on_day, 4) AS avg_page_views_per_user
FROM daily_pageviews
ORDER BY event_date;