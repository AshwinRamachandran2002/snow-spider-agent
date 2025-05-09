SELECT product.v2ProductName AS Product_Name, COUNT(*) AS Number_of_Purchases
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS sessions,
UNNEST(sessions.hits) AS hit,
UNNEST(hit.product) AS product
WHERE sessions.fullVisitorId IN (
  SELECT DISTINCT sessions2.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS sessions2,
  UNNEST(sessions2.hits) AS hit2,
  UNNEST(hit2.product) AS product2
  WHERE LOWER(product2.v2ProductName) LIKE '%youtube%'
)
AND LOWER(product.v2ProductName) NOT LIKE '%youtube%'
GROUP BY product.v2ProductName
ORDER BY Number_of_Purchases DESC
LIMIT 1;