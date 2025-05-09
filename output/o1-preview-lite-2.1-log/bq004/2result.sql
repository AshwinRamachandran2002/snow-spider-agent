SELECT product.v2ProductName AS Product_Name, COUNT(*) AS Number_of_Purchases
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS sessions
CROSS JOIN UNNEST(sessions.hits) AS hits
CROSS JOIN UNNEST(hits.product) AS product
WHERE sessions.fullVisitorId IN (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
  CROSS JOIN UNNEST(hits) AS hits
  CROSS JOIN UNNEST(hits.product) AS product
  WHERE hits.eCommerceAction.action_type = '6'
    AND LOWER(product.v2ProductName) LIKE '%youtube%'
)
  AND hits.eCommerceAction.action_type = '6'
  AND LOWER(product.v2ProductName) NOT LIKE '%youtube%'
GROUP BY product.v2ProductName
ORDER BY Number_of_Purchases DESC
LIMIT 1