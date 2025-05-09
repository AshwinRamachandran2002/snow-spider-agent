SELECT product.v2ProductName AS Product_Name, COUNT(*) AS Number_of_Purchases
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS sessions,
  UNNEST(sessions.hits) AS hits,
  UNNEST(hits.product) AS product
WHERE CONCAT(sessions.fullVisitorId, CAST(sessions.visitId AS STRING)) IN (
  SELECT DISTINCT CONCAT(s.fullVisitorId, CAST(s.visitId AS STRING))
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
    UNNEST(s.hits) AS h,
    UNNEST(h.product) AS p
  WHERE LOWER(p.v2ProductName) LIKE '%youtube%'
    AND h.eCommerceAction.action_type = "6"
)
  AND LOWER(product.v2ProductName) NOT LIKE '%youtube%'
  AND hits.eCommerceAction.action_type = "6"
GROUP BY product.v2ProductName
ORDER BY Number_of_Purchases DESC
LIMIT 1