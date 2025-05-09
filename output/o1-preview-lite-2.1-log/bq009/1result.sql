WITH total_revenue_per_source AS (
    SELECT
        trafficSource.source AS source,
        SUM(totals.totalTransactionRevenue) AS total_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    WHERE totals.totalTransactionRevenue IS NOT NULL
    GROUP BY source
),
max_revenue_source AS (
    SELECT source
    FROM total_revenue_per_source
    ORDER BY total_revenue DESC
    LIMIT 1
),
monthly_rev AS (
    SELECT
        trafficSource.source AS source,
        EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS month,
        SUM(totals.totalTransactionRevenue) AS monthly_rev
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    WHERE totals.totalTransactionRevenue IS NOT NULL
    GROUP BY source, month
)
SELECT
    mr.source AS TrafficSource,
    ROUND((MAX(mr.monthly_rev) - MIN(mr.monthly_rev)) / 1000000, 4) AS RevenueDifference_Millions
FROM monthly_rev mr
WHERE mr.source IN (SELECT source FROM max_revenue_source)
GROUP BY mr.source