-- Page‑view totals and per‑user averages for Nov‑2020,
-- limited to users who generated at least one purchase in Nov‑2020
WITH purchased_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'         -- identify purchasers
)

SELECT
  DATE(PARSE_DATE('%Y%m%d', event_date))                     AS event_date,
  COUNT(*)                                                   AS total_page_views,
  SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id))      AS avg_page_views_per_user
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND event_name = 'page_view'                               -- only page‑view events
  AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchased_users)
GROUP BY event_date
ORDER BY event_date;