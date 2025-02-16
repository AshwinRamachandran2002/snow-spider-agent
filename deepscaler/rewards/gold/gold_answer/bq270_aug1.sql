-- Task: What is the number of product views per month from January to March 2017?
SELECT
  CONCAT(EXTRACT(YEAR FROM (PARSE_DATE('%Y%m%d', date))), '0',
         EXTRACT(MONTH FROM (PARSE_DATE('%Y%m%d', date)))) AS month,
  COUNT(hits.eCommerceAction.action_type) AS num_product_view
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits
WHERE _table_suffix BETWEEN '0101' AND '0331'
  AND hits.eCommerceAction.action_type = '2'
GROUP BY month
ORDER BY month;