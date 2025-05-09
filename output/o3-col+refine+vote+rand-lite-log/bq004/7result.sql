WITH yt_buyers AS (
  -- 1.  All visitors who purchased at least one YouTube-related item in July-2017
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
    AND p.productQuantity > 0
    AND LOWER(p.v2ProductName) LIKE '%youtube%'
),
product_totals AS (
  -- 2.  Aggregate quantity of every non-YouTube product bought by those visitors
  SELECT
    p.v2ProductName                AS product_name,
    SUM(p.productQuantity) AS total_qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE p.productQuantity IS NOT NULL
    AND p.productQuantity > 0
    AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'       -- exclude YouTube items
    AND s.fullVisitorId IN (SELECT fullVisitorId FROM yt_buyers)
  GROUP BY p.v2ProductName
)
-- 3.  Return the product with the highest total quantity
SELECT product_name, total_qty
FROM product_totals
ORDER BY total_qty DESC
LIMIT 1;