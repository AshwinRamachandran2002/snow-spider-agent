WITH user_activity AS (
  -- 1. Roll‑up December 2020 activity for every visitor
  SELECT
    user_pseudo_id,
    SUM(CASE WHEN event_name = 'page_view'  THEN 1 ELSE 0 END) AS pageviews,
    MAX(CASE WHEN event_name = 'purchase'   THEN 1 ELSE 0 END) AS is_purchaser   -- 1 = purchaser, 0 = non‑purchaser
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  -- the wildcard already limits us to December 2020; the suffix guard avoids accidental spills
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  GROUP BY user_pseudo_id
)

-- 2. Compare the two segments
SELECT
  AVG(IF(is_purchaser = 1, pageviews, NULL)) AS avg_pageviews_purchasers,
  AVG(IF(is_purchaser = 0, pageviews, NULL)) AS avg_pageviews_non_purchasers,
  -- requested metric: purchasers’ average minus non‑purchasers’ average
  AVG(IF(is_purchaser = 1, pageviews, NULL))
  - AVG(IF(is_purchaser = 0, pageviews, NULL)) AS avg_pageviews_difference
FROM user_activity;