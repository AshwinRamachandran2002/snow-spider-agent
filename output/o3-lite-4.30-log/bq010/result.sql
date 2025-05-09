-- Top‑selling (by quantity) product that “YouTube Men's Vintage Henley” buyers also purchased in July 2017
WITH july_2017_sessions AS (
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170701` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170702` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170703` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170704` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170705` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170706` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170707` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170708` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170709` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170710` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170711` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170712` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170713` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170714` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170715` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170716` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170717` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170718` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170719` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170720` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170721` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170722` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170723` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170724` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170725` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170726` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170727` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170728` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170729` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170730` UNION ALL
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170731`
),
henley_buyers AS (
  -- Visitors who completed a purchase of the Henley
  SELECT DISTINCT s.fullVisitorId
  FROM   july_2017_sessions AS s
  CROSS  JOIN UNNEST(s.hits)    AS h
  CROSS  JOIN UNNEST(h.product) AS p
  WHERE  p.v2ProductName = 'YouTube Men\'s Vintage Henley'
    AND  h.eCommerceAction.action_type = '6'
)
SELECT
  p.v2ProductName AS product_name
FROM   july_2017_sessions s
JOIN   henley_buyers b
  ON   s.fullVisitorId = b.fullVisitorId
CROSS  JOIN UNNEST(s.hits)    AS h
CROSS  JOIN UNNEST(h.product) AS p
WHERE  p.v2ProductName <> 'YouTube Men\'s Vintage Henley'
  AND  h.eCommerceAction.action_type = '6'
GROUP  BY product_name
ORDER  BY SUM(p.productQuantity) DESC,
          SUM(p.productRevenue)  DESC
LIMIT 1;