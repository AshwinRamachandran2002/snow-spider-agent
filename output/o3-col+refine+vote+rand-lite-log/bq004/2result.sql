WITH yt_buyers AS (
  -- Visitors who bought at least one product whose name contains “youtube”
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
    AND LOWER(p.v2ProductName) LIKE '%youtube%'
),

other_products AS (
  -- For those visitors, aggregate quantities of all NON-YouTube products
  SELECT
    p.v2ProductName              AS product_name,
    SUM(p.productQuantity)       AS total_qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
  JOIN yt_buyers USING (fullVisitorId),
  UNNEST(s.hits)    AS h,
  UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
    AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'
  GROUP BY product_name
)

-- Product (excluding YouTube-named ones) with the highest total quantity
SELECT product_name, total_qty
FROM   other_products
ORDER  BY total_qty DESC
LIMIT  1;