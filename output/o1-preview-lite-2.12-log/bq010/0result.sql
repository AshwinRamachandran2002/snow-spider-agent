SELECT p.v2ProductName AS Product_Name, SUM(p.productQuantity) AS Total_Sales
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
  UNNEST(s.hits) AS h,
  UNNEST(h.product) AS p
WHERE s.fullVisitorId IN (
  SELECT DISTINCT s2.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s2,
    UNNEST(s2.hits) AS h2,
    UNNEST(h2.product) AS p2
  WHERE h2.eCommerceAction.action_type = '6'
    AND LOWER(p2.v2ProductName) = LOWER('Youtube Men\'s Vintage Henley')
)
AND h.eCommerceAction.action_type = '6'
AND LOWER(p.v2ProductName) != LOWER('Youtube Men\'s Vintage Henley')
GROUP BY p.v2ProductName
ORDER BY Total_Sales DESC
LIMIT 1;