-- Average page‑views for buyers vs. non‑buyers in December 2020
WITH user_dec2020 AS (
  SELECT
    user_pseudo_id,
    SUM(CASE WHEN event_name = 'page_view'  THEN 1 ELSE 0 END) AS pageviews,
    MAX(CASE WHEN event_name = 'purchase'   THEN 1 ELSE 0 END) AS purchaser_flag  -- 1 if user bought
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  GROUP BY user_pseudo_id
)

SELECT
  AVG(IF(purchaser_flag = 1, pageviews, NULL)) AS avg_pageviews_purchasers,
  AVG(IF(purchaser_flag = 0, pageviews, NULL)) AS avg_pageviews_non_purchasers,
  AVG(IF(purchaser_flag = 1, pageviews, NULL)) -
  AVG(IF(purchaser_flag = 0, pageviews, NULL)) AS average_difference
FROM user_dec2020;