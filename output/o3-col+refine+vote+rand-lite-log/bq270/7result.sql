WITH product_detail_views AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    COUNT(*) AS detail_views
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND SAFE_CAST(h.eCommerceAction.action_type AS INT64) = 2   -- product-detail views
  GROUP BY month
),
add_to_cart_hits AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    COUNT(*) AS cart_hits
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND SAFE_CAST(h.eCommerceAction.action_type AS INT64) = 3   -- add-to-cart
  GROUP BY month
),
purchase_hits AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    COUNT(*) AS purchase_hits
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND SAFE_CAST(h.eCommerceAction.action_type AS INT64) = 6   -- purchase
  GROUP BY month
)
SELECT
  d.month,
  ROUND(100 * c.cart_hits      / d.detail_views, 4) AS add_to_cart_rate_pct,
  ROUND(100 * p.purchase_hits  / d.detail_views, 4) AS purchase_rate_pct
FROM product_detail_views d
LEFT JOIN add_to_cart_hits c USING(month)
LEFT JOIN purchase_hits   p USING(month)
WHERE d.month BETWEEN '2017-01' AND '2017-03'
ORDER BY d.month;