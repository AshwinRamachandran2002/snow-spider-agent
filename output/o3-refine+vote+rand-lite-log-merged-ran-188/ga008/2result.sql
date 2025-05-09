-- Page views in Nov‑2020 for users who purchased in Nov‑2020
WITH purchasers AS (                         -- 1. find purchasers during Nov‑2020
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
),

page_views AS (                              -- 2. keep only page‑view rows for those purchasers
  SELECT
    event_date,                              -- YYYYMMDD
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchasers)
)

-- 3. aggregate
SELECT
  event_date,
  COUNT(*)                                            AS total_page_views,
  SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id)) AS avg_page_views_per_user
FROM page_views
GROUP BY event_date
ORDER BY event_date;