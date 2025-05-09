-- Top-selling product (by units) among customers who bought
-- “YouTube Men’s Vintage Henley” during July-2017 sessions,
-- excluding the Henley itself.
WITH henley_buyers AS (
  SELECT DISTINCT
         s.fullVisitorId
  FROM   `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS  JOIN UNNEST(s.hits)    AS h
  CROSS  JOIN UNNEST(h.product) AS p
  WHERE  LOWER(p.v2ProductName) LIKE '%youtube%'      -- brand
     AND LOWER(p.v2ProductName) LIKE '%vintage%'      -- model
     AND LOWER(p.v2ProductName) LIKE '%henley%'       -- style
),

products_sold AS (
  SELECT
    p.v2ProductName                              AS product_name,
    SUM(IFNULL(p.productQuantity,1))             AS units_sold
  FROM   `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS  JOIN UNNEST(s.hits)    AS h
  CROSS  JOIN UNNEST(h.product) AS p
  WHERE  s.fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
    -- exclude the Henley itself
    AND NOT (LOWER(p.v2ProductName) LIKE '%youtube%'
         AND LOWER(p.v2ProductName) LIKE '%vintage%'
         AND LOWER(p.v2ProductName) LIKE '%henley%')
  GROUP BY product_name
)

SELECT
  product_name,
  units_sold
FROM products_sold
ORDER BY units_sold DESC
LIMIT 1;