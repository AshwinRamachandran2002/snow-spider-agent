SELECT
  hp.v2ProductName AS Product_Name,
  SUM(hp.productQuantity) AS Total_Quantity_Purchased
FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS t
  CROSS JOIN UNNEST(t.hits) AS h
  CROSS JOIN UNNEST(h.product) AS hp
WHERE
  t.fullVisitorId IN (
    SELECT DISTINCT
      t.fullVisitorId
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS t
      CROSS JOIN UNNEST(t.hits) AS h
      CROSS JOIN UNNEST(h.product) AS hp
    WHERE
      LOWER(hp.v2ProductName) LIKE '%youtube%'
  )
  AND LOWER(hp.v2ProductName) NOT LIKE '%youtube%'
GROUP BY
  hp.v2ProductName
ORDER BY
  Total_Quantity_Purchased DESC
LIMIT 1