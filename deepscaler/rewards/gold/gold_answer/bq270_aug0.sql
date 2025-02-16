-- Task: From January to March 2017, calculate the monthly conversion rates for add-to-cart and purchase actions based on product detail views. The add-to-cart conversion rate is calculated as the percentage of product detail views (action_type = '2') that resulted in add-to-cart actions (action_type = '3'). The purchase conversion rate is calculated as the percentage of product detail views that resulted in purchase actions (action_type = '6' and productRevenue is not null).

WITH
  cte1 AS
    (SELECT
      CONCAT(EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', date)), '0',
             EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date))) AS month,
      COUNT(hits.eCommerceAction.action_type) AS num_product_view
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS hits
    WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
      AND hits.eCommerceAction.action_type = '2'
    GROUP BY month),
  cte2 AS
    (SELECT
      CONCAT(EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', date)), '0',
             EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date))) AS month,
      COUNT(hits.eCommerceAction.action_type) AS num_addtocart
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS hits
    WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
      AND hits.eCommerceAction.action_type = '3'
    GROUP BY month),
  cte3 AS
    (SELECT
      CONCAT(EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', date)), '0',
             EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date))) AS month,
      COUNT(hits.eCommerceAction.action_type) AS num_purchase
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
      AND hits.eCommerceAction.action_type = '6'
      AND product.productRevenue IS NOT NULL
    GROUP BY month)
SELECT 
  ROUND((num_addtocart / num_product_view * 100), 2) AS add_to_cart_rate,
  ROUND((num_purchase / num_product_view * 100), 2) AS purchase_rate
FROM cte1
  LEFT JOIN cte2 USING(month)
  LEFT JOIN cte3 USING(month)
ORDER BY month;