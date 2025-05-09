/* Top‑selling product (by quantity) among customers who purchased
   “YouTube Men’s Vintage Henley” in July‑2017, excluding the Henley itself */
WITH henley_buyers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits)      AS hit
  CROSS JOIN UNNEST(hit.product) AS prod
  WHERE prod.productQuantity IS NOT NULL
        -- identify the specific Henley purchase
        AND LOWER(prod.v2ProductName) LIKE '%youtube%'
        AND LOWER(prod.v2ProductName) LIKE '%vintage%'
        AND LOWER(prod.v2ProductName) LIKE '%henley%'
        AND LOWER(prod.v2ProductName) LIKE '%men%'
)

SELECT
  prod.v2ProductName                    AS top_selling_product,
  SUM(IFNULL(prod.productQuantity,1))   AS total_qty_sold
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
JOIN henley_buyers USING (fullVisitorId)
CROSS JOIN UNNEST(s.hits)      AS hit
CROSS JOIN UNNEST(hit.product) AS prod
WHERE prod.productQuantity IS NOT NULL
      -- exclude the Henley itself
      AND NOT (  LOWER(prod.v2ProductName) LIKE '%youtube%'
              AND LOWER(prod.v2ProductName) LIKE '%vintage%'
              AND LOWER(prod.v2ProductName) LIKE '%henley%'
              AND LOWER(prod.v2ProductName) LIKE '%men%' )
GROUP BY top_selling_product
ORDER BY total_qty_sold DESC
LIMIT 1;