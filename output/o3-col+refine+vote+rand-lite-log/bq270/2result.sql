-- Monthly add-to-cart and purchase conversion rates
-- (as % of product–detail pageviews) for Jan-Mar 2017  
SELECT
  month,
  ROUND(100 * add_to_cart / detail_views , 4) AS add_to_cart_pct,
  ROUND(100 * purchases   / detail_views , 4) AS purchase_pct
FROM (
  SELECT
    CONCAT('2017-', SUBSTR(_TABLE_SUFFIX, 1, 2))            AS month,
    COUNTIF(h.eCommerceAction.action_type = '2')            AS detail_views,   -- product-detail views
    COUNTIF(h.eCommerceAction.action_type = '3')            AS add_to_cart,    -- add-to-cart actions
    COUNTIF(h.eCommerceAction.action_type = '6')            AS purchases       -- completed purchases
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'             -- Jan-Mar 2017
  GROUP BY month
)
ORDER BY month;