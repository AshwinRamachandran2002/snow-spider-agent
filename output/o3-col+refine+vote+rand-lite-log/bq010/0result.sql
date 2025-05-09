-- Top-selling (by quantity) product bought by July-2017 customers
-- who purchased “YouTube Men’s Vintage Henley”, excluding the Henley itself.
WITH henley_buyers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)    AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE LOWER(p.v2ProductName) LIKE '%vintage%henley%'          -- the Henley
        AND COALESCE(p.productQuantity,0) > 0                   -- ensure purchase
)

SELECT
  p.v2ProductName                          AS product_name,
  SUM(COALESCE(p.productQuantity,1))       AS total_qty
FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
CROSS JOIN UNNEST(s.hits)    AS h
CROSS JOIN UNNEST(h.product) AS p
WHERE s.fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
      AND LOWER(p.v2ProductName) NOT LIKE '%vintage%henley%'    -- exclude Henley itself
GROUP BY product_name
ORDER BY total_qty DESC
LIMIT 1;