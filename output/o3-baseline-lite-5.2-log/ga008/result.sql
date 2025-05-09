/*  Page‑views per day in November‑2020 for users who purchased in the same month */
WITH purchased_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
),
pageviews AS (
  SELECT
    event_date,
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchased_users)
)
SELECT
  PARSE_DATE('%Y%m%d', event_date)           AS event_day,
  COUNT(*)                                   AS total_page_views,
  SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id))
                                             AS avg_page_views_per_user
FROM pageviews
GROUP BY event_day
ORDER BY event_day;