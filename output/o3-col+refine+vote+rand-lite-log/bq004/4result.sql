-- Non-YouTube product with the highest total quantity purchased in July-2017
-- by visitors who bought at least one YouTube-related product the same month
WITH youtube_buyers AS (
  SELECT DISTINCT s.fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  JOIN UNNEST(s.hits)    AS h
  JOIN UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
    AND p.productQuantity IS NOT NULL
    AND LOWER(p.v2ProductName) LIKE '%youtube%'
)

SELECT
  p.v2ProductName  AS product_name,
  SUM(p.productQuantity) AS total_quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
JOIN UNNEST(s.hits)    AS h
JOIN UNNEST(h.product) AS p
WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
  AND p.productQuantity IS NOT NULL
  AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'     -- exclude YouTube products
  AND s.fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
GROUP BY product_name
ORDER BY total_quantity DESC
LIMIT 1;