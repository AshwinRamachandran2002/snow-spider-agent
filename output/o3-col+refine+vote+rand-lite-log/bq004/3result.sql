-- Top non-YouTube product (by quantity) bought in July-2017 by visitors
-- who purchased at least one YouTube-related item
WITH yt_buyers AS (          -- all July-2017 visitors who bought a YouTube product
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE p.productRevenue IS NOT NULL
        AND LOWER(p.v2ProductName) LIKE '%youtube%'
),
product_totals AS (          -- aggregate quantity of other products bought by them
  SELECT
    p.productSku,
    p.v2ProductName               AS productName,
    SUM(IFNULL(p.productQuantity,1)) AS total_qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s,
       UNNEST(s.hits)    AS h,
       UNNEST(h.product) AS p
  WHERE s.fullVisitorId IN (SELECT fullVisitorId FROM yt_buyers)
        AND p.productRevenue IS NOT NULL
        AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'
  GROUP BY p.productSku, p.v2ProductName
),
ranked AS (                   -- rank products by total quantity
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY total_qty DESC) AS rn
  FROM product_totals
)
SELECT productSku,
       productName,
       total_qty AS max_total_quantity
FROM   ranked
WHERE  rn = 1;