WITH visitors_who_bought_youtube AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS session,
  UNNEST(session.hits) AS hit,
  UNNEST(hit.product) AS product
  WHERE product.v2ProductName IS NOT NULL
    AND LOWER(product.v2ProductName) LIKE '%youtube%'
)

SELECT 
  product.v2ProductName AS Product_Name, 
  SUM(product.productQuantity) AS Total_Quantity_Purchased
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS session,
UNNEST(session.hits) AS hit,
UNNEST(hit.product) AS product
WHERE session.fullVisitorId IN (
    SELECT fullVisitorId FROM visitors_who_bought_youtube
  )
  AND product.v2ProductName IS NOT NULL
  AND LOWER(product.v2ProductName) NOT LIKE '%youtube%'
GROUP BY product.v2ProductName
ORDER BY Total_Quantity_Purchased DESC
LIMIT 1