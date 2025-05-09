-- Top non‑YouTube product (by quantity) bought by visitors who purchased any YouTube item in July‑2017
WITH youtube_buyers AS (
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits)        AS hit,
       UNNEST(hit.product) AS prod
  WHERE prod.productQuantity IS NOT NULL
    AND LOWER(prod.v2ProductName) LIKE '%youtube%'          -- buyers of YouTube‑related products
),
non_youtube_totals AS (
  SELECT
    prod.v2ProductName              AS product_name,
    SUM(prod.productQuantity)       AS total_qty
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits)        AS hit,
       UNNEST(hit.product) AS prod
  WHERE prod.productQuantity IS NOT NULL
    AND LOWER(prod.v2ProductName) NOT LIKE '%youtube%'      -- exclude YouTube products
    AND fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
  GROUP BY product_name
)
SELECT product_name, total_qty
FROM non_youtube_totals
ORDER BY total_qty DESC
LIMIT 1;