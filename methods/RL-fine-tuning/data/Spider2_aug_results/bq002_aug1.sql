-- Task: During the first half of 2017, which traffic source generated the highest total product revenue based on hits product revenue?
SELECT
  CONCAT(trafficSource.source, '/', trafficSource.medium) AS traffic_source,
  SUM(product.productRevenue) AS total_product_revenue
FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
WHERE
  _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
  AND product.productRevenue IS NOT NULL
GROUP BY
  traffic_source
ORDER BY
  total_product_revenue DESC
LIMIT 1;