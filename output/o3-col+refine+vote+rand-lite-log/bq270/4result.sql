-- Monthly add-to-cart and purchase conversion rates
-- ( % of product-detail pageviews )  •  Jan–Mar 2017
SELECT
  month,
  ROUND(SAFE_DIVIDE(add_to_cart , detail_views) * 100, 4) AS add_to_cart_conv_rate_pct,
  ROUND(SAFE_DIVIDE(purchases  , detail_views) * 100, 4) AS purchase_conv_rate_pct
FROM (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(CASE WHEN h.eCommerceAction.action_type = '2'
              AND (p.isImpression IS NULL OR p.isImpression = FALSE) THEN 1 ELSE 0 END) AS detail_views,
    SUM(CASE WHEN h.eCommerceAction.action_type = '3' THEN 1 ELSE 0 END)               AS add_to_cart,
    SUM(CASE WHEN h.eCommerceAction.action_type = '6' THEN 1 ELSE 0 END)               AS purchases
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  CROSS JOIN UNNEST(hits) AS h
  LEFT  JOIN UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  GROUP BY month
)
ORDER BY month;