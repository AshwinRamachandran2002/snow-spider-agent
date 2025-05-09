WITH all_sessions AS (
    SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170701`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170702`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170703`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170704`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170705`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170706`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170707`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170708`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170709`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170710`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170711`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170712`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170713`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170714`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170715`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170716`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170717`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170718`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170719`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170720`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170721`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170722`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170723`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170724`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170725`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170726`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170727`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170728`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170729`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170730`
    UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170731`
),
buyers AS (
    SELECT DISTINCT fullVisitorId
    FROM all_sessions
    CROSS JOIN UNNEST(hits) AS h
    CROSS JOIN UNNEST(h.product) AS h_product
    WHERE LOWER(h_product.v2ProductName) = 'youtube men\'s vintage henley'
    AND h.eCommerceAction.action_type = '6'
),
sales_data AS (
    SELECT
        other_products.v2ProductName AS Product_Name,
        ROUND(SUM(other_products.productRevenue)/1e6, 4) AS Total_Sales
    FROM all_sessions AS t
    INNER JOIN buyers ON t.fullVisitorId = buyers.fullVisitorId
    CROSS JOIN UNNEST(t.hits) AS h2
    CROSS JOIN UNNEST(h2.product) AS other_products
    WHERE LOWER(other_products.v2ProductName) != 'youtube men\'s vintage henley'
    AND h2.eCommerceAction.action_type = '6'
    GROUP BY other_products.v2ProductName
)
SELECT Product_Name, Total_Sales
FROM sales_data
ORDER BY Total_Sales DESC
LIMIT 1;