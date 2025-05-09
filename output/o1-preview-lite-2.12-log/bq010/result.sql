WITH sessions AS (
    SELECT *
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
),
customers AS (
    SELECT DISTINCT fullVisitorId
    FROM sessions s
    CROSS JOIN UNNEST(s.hits) AS hit
    CROSS JOIN UNNEST(hit.product) AS prod
    WHERE LOWER(prod.v2ProductName) = LOWER('YouTube Men\'s Vintage Henley')
      AND hit.eCommerceAction.action_type = '6'
),
purchases AS (
    SELECT prod.v2ProductName AS Product_Name, prod.productQuantity AS Product_Quantity
    FROM sessions s
    INNER JOIN customers c ON s.fullVisitorId = c.fullVisitorId
    CROSS JOIN UNNEST(s.hits) AS hit
    CROSS JOIN UNNEST(hit.product) AS prod
    WHERE LOWER(prod.v2ProductName) != LOWER('YouTube Men\'s Vintage Henley')
      AND hit.eCommerceAction.action_type = '6'
)
SELECT Product_Name, SUM(Product_Quantity) AS Total_Sales
FROM purchases
GROUP BY Product_Name
ORDER BY Total_Sales DESC
LIMIT 1;