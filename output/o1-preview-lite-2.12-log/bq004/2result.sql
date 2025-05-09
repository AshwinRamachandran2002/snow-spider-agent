SELECT 
  product.v2ProductName AS Product_Name, 
  SUM(COALESCE(product.productQuantity, 1)) AS Total_Quantity_Purchased
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS session,
  UNNEST(session.hits) AS hit,
  UNNEST(hit.product) AS product
WHERE 
  session.fullVisitorId IN (
    SELECT DISTINCT fullVisitorId
    FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
      UNNEST(hits) AS hit_youtube,
      UNNEST(hit_youtube.product) AS product_youtube
    WHERE 
      LOWER(product_youtube.v2ProductName) LIKE '%youtube%'
      AND hit_youtube.eCommerceAction.action_type = '6'
  )
  AND LOWER(product.v2ProductName) NOT LIKE '%youtube%'
  AND hit.eCommerceAction.action_type = '6'
GROUP BY 
  Product_Name
ORDER BY 
  Total_Quantity_Purchased DESC
LIMIT 1