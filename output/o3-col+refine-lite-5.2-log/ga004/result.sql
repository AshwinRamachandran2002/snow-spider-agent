-- Average page‑view difference (purchasers minus non‑purchasers) for Dec‑2020
WITH pageviews AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS pageviews
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'page_view'
  GROUP BY user_pseudo_id
),
purchasers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'purchase'
),
avg_views AS (
  SELECT
    IF(p.user_pseudo_id IS NULL, 0, 1) AS is_purchaser,
    AVG(pv.pageviews)                  AS avg_pageviews
  FROM pageviews pv
  LEFT JOIN purchasers p USING (user_pseudo_id)
  GROUP BY is_purchaser
)
SELECT
  ROUND(
    MAX(IF(is_purchaser = 1, avg_pageviews, NULL)) -
    MAX(IF(is_purchaser = 0, avg_pageviews, NULL)),
    4
  ) AS avg_pageview_difference
FROM avg_views;