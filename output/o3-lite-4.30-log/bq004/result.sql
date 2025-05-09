WITH july_sessions AS (
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170701` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170702` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170703` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170704` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170705` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170706` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170707` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170708` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170709` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170710` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170711` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170712` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170713` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170714` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170715` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170716` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170717` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170718` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170719` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170720` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170721` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170722` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170723` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170724` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170725` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170726` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170727` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170728` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170729` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170730` UNION ALL
  SELECT fullVisitorId, hits FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170731`
),
all_product_hits AS (
  SELECT
    s.fullVisitorId,
    p.v2ProductName                  AS product_name,
    p.productQuantity                AS qty
  FROM july_sessions AS s
  CROSS JOIN UNNEST(s.hits)    AS h
  CROSS JOIN UNNEST(h.product) AS p
  WHERE p.v2ProductName IS NOT NULL
    AND p.productQuantity IS NOT NULL
    AND p.productQuantity > 0          -- purchase (not just impression)
),
youtube_buyers AS (            -- visitors who purchased any YouTube‑related product
  SELECT DISTINCT fullVisitorId
  FROM all_product_hits
  WHERE LOWER(product_name) LIKE '%youtube%'
)
SELECT
  product_name,
  SUM(qty) AS total_quantity
FROM all_product_hits
WHERE fullVisitorId IN (SELECT fullVisitorId FROM youtube_buyers)
  AND LOWER(product_name) NOT LIKE '%youtube%'   -- exclude YouTube products
GROUP BY product_name
ORDER BY total_quantity DESC
LIMIT 1;