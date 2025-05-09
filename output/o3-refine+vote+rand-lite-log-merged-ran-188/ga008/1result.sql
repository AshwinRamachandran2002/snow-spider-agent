-- Total and average page‑views per day in Nov‑2020
WITH purchase_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
),

page_view_events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date)        AS event_day,
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchase_users)
)

SELECT
  event_day,
  COUNT(*)                                                       AS total_page_views,
  COUNT(DISTINCT user_pseudo_id)                                 AS users_with_page_views,
  SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id))          AS avg_page_views_per_user
FROM page_view_events
GROUP BY event_day
ORDER BY event_day;