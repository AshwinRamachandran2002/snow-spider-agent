-- Top non-YouTube product (by quantity) purchased in July-2017
WITH youtube_buyers AS (          -- visitors who bought any YouTube-related product
  SELECT DISTINCT fullVisitorId
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)      AS h
  CROSS JOIN UNNEST(h.product)   AS p
  WHERE LOWER(p.v2ProductName) LIKE '%youtube%'
)

SELECT
  p.v2ProductName        AS product_name,
  SUM(p.productQuantity) AS total_quantity_purchased
FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
CROSS JOIN UNNEST(s.hits)      AS h
CROSS JOIN UNNEST(h.product)   AS p
WHERE s.fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)   -- only YouTube buyers
  AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'                     -- exclude YouTube products
GROUP BY product_name
ORDER BY total_quantity_purchased DESC
LIMIT 1;