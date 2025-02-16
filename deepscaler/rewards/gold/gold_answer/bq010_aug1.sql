-- Task: List the IDs of customers who purchased "YouTube Men's Vintage Henley" in July 2017.
SELECT 
    DISTINCT fullVisitorId AS Henley_CUSTOMER_ID
FROM 
    `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE
    product.v2ProductName = "YouTube Men's Vintage Henley"
    AND product.productRevenue IS NOT NULL;