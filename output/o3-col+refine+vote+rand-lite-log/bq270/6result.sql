/* Monthly add-to-cart & purchase conversion rates
   (as % of product-detail pageviews) – Jan‒Mar 2017               */

WITH product_detail_views AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(1)                                          AS views
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)   AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type = '2'                 -- product-detail
    AND (p.isImpression IS NULL OR p.isImpression = FALSE)  -- exclude list impressions
  GROUP BY month
),
add_to_cart_events AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(1)                                          AS add_to_cart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type = '3'                 -- add-to-cart
  GROUP BY month
),
purchase_events AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(1)                                          AS purchases
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type = '6'                 -- completed purchase
  GROUP BY month
)

SELECT
  v.month                                    AS month_yyyy_mm,
  CONCAT(ROUND(100 * c.add_to_cart / v.views, 2), '%') AS add_to_cart_conversion,
  CONCAT(ROUND(100 * p.purchases  / v.views, 2), '%') AS purchase_conversion
FROM product_detail_views v
LEFT JOIN add_to_cart_events c USING (month)
LEFT JOIN purchase_events    p USING (month)
ORDER BY month_yyyy_mm;