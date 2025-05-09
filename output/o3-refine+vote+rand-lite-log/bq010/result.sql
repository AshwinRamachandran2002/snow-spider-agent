WITH henley_buyers AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits) AS h,
       UNNEST(h.product) AS p
  WHERE p.productRevenue IS NOT NULL
    AND p.v2ProductName = "YouTube Men's Vintage Henley"
),
other_purchases AS (
  SELECT
    p.v2ProductName AS product_name,
    SUM(COALESCE(p.productQuantity, 1)) AS total_qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits) AS h,
       UNNEST(h.product) AS p
  WHERE p.productRevenue IS NOT NULL
    AND fullVisitorId IN (SELECT fullVisitorId FROM henley_buyers)
    AND p.v2ProductName != "YouTube Men's Vintage Henley"
  GROUP BY product_name
)
SELECT product_name, total_qty
FROM other_purchases
ORDER BY total_qty DESC
LIMIT 1;