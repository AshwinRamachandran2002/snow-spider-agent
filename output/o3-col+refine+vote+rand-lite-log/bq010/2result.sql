-- Top-selling product (by total revenue) among customers who bought
-- “YouTube Men’s Vintage Henley” in July-2017, excluding the Henley itself
WITH henley_buyers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  CROSS JOIN UNNEST(s.hits) AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE LOWER(p.v2ProductName) LIKE '%vintage%'     -- identifies the Henley
    AND LOWER(p.v2ProductName) LIKE '%henley%'
    AND p.productRevenue IS NOT NULL                -- only count actual purchases
)

SELECT
  p.v2ProductName               AS top_selling_product,
  SUM(p.productRevenue) / 1e6   AS total_revenue_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
JOIN henley_buyers hb
  ON s.fullVisitorId = hb.fullVisitorId
CROSS JOIN UNNEST(s.hits) AS h
CROSS JOIN UNNEST(h.product) AS p
WHERE p.productRevenue IS NOT NULL                  -- purchased products only
  AND NOT (LOWER(p.v2ProductName) LIKE '%vintage%'  -- exclude the Henley itself
           AND LOWER(p.v2ProductName) LIKE '%henley%')
GROUP BY p.v2ProductName
ORDER BY total_revenue_usd DESC
LIMIT 1;