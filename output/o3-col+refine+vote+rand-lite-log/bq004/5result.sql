WITH youtube_buyers AS (
  -- Visitors who bought at least one YouTube-branded item in July-2017
  SELECT DISTINCT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
       UNNEST(hits)      AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
    AND p.productQuantity IS NOT NULL
    AND LOWER(p.v2ProductName) LIKE '%youtube%'
)

SELECT
  p.v2ProductName AS product,
  SUM(p.productQuantity) AS total_quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS s
JOIN UNNEST(s.hits)      AS h
JOIN UNNEST(h.product)   AS p
ON TRUE
WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
  AND s.fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
  AND p.productQuantity IS NOT NULL
  AND LOWER(p.v2ProductName) NOT LIKE '%youtube%'
GROUP BY product
ORDER BY total_quantity DESC
LIMIT 1;