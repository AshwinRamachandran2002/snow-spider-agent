-- Top-selling (by quantity) product purchased by customers who bought
-- “YouTube Men’s Vintage Henley” in July-2017, excluding that Henley itself
WITH henley_buyers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE p.productRevenue > 0
    AND LOWER(p.v2ProductName) = 'youtube men\'s vintage henley'
)

SELECT
  p.v2ProductName       AS top_product,
  SUM(IFNULL(p.productQuantity,1)) AS total_qty_sold
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
     UNNEST(s.hits)    AS h,
     UNNEST(h.product) AS p
WHERE s.fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
  AND p.productRevenue > 0
  AND LOWER(p.v2ProductName) <> 'youtube men\'s vintage henley'
GROUP BY top_product
ORDER BY total_qty_sold DESC
LIMIT 1;