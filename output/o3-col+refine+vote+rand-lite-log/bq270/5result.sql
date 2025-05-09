/* Monthly add-to-cart and purchase conversion rates (% of product-detail pageviews)
   for January-March 2017                                                      */
WITH product_detail_views AS (
  SELECT
    SUBSTR(date,1,6) AS yyyymm,
    COUNT(*)         AS detail_views
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type = '2'        -- product-detail views
  GROUP BY yyyymm
),
add_to_cart_events AS (
  SELECT
    SUBSTR(date,1,6) AS yyyymm,
    COUNT(*)         AS add_to_cart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type = '3'        -- add-to-cart
  GROUP BY yyyymm
),
purchase_events AS (
  SELECT
    SUBSTR(date,1,6) AS yyyymm,
    COUNT(*)         AS purchases
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type = '6'        -- completed purchase
  GROUP BY yyyymm
)
SELECT
  FORMAT_DATE('%b %Y', PARSE_DATE('%Y%m', d.yyyymm))            AS month,
  ROUND(100.0 * c.add_to_cart / d.detail_views, 4)  AS add_to_cart_rate_pct,
  ROUND(100.0 * p.purchases   / d.detail_views, 4)  AS purchase_rate_pct
FROM product_detail_views d
LEFT JOIN add_to_cart_events c USING (yyyymm)
LEFT JOIN purchase_events   p USING (yyyymm)
ORDER BY d.yyyymm;