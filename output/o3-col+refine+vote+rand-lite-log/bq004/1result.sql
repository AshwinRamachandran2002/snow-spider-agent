-- Top non-YouTube product (by total quantity) bought by visitors who purchased any YouTube product in July-2017
WITH yt_buyers AS (          -- visitors who bought ≥1 YouTube-related item
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)      AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
    AND p.productRevenue IS NOT NULL
    AND LOWER(p.v2ProductName) LIKE '%youtube%'
)

SELECT
  p.v2ProductName        AS product_name,
  SUM(p.productQuantity) AS total_quantity_purchased
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
     UNNEST(hits)      AS h,
     UNNEST(h.product) AS p
WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
  AND fullVisitorId IN (SELECT fullVisitorId FROM yt_buyers)
  AND p.productRevenue IS NOT NULL
  AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'      -- exclude YouTube items
GROUP BY product_name
ORDER BY total_quantity_purchased DESC
LIMIT 1;