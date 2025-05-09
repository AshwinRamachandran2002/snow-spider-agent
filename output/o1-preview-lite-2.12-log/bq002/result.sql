WITH source_revenue AS (
    SELECT 
        trafficSource.source AS source, 
        SUM(product.productRevenue)/1e6 AS total_revenue_millions
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        source
    ORDER BY 
        total_revenue_millions DESC
    LIMIT 1
), daily_revenue AS (
    SELECT 
        date, 
        trafficSource.source AS source,
        SUM(product.productRevenue)/1e6 AS daily_revenue_millions
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        date, source
), weekly_revenue AS (
    SELECT 
        FORMAT_DATE('%Y-%V', PARSE_DATE('%Y%m%d', date)) AS week, 
        trafficSource.source AS source,
        SUM(product.productRevenue)/1e6 AS weekly_revenue_millions
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        week, source
), monthly_revenue AS (
    SELECT 
        FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month, 
        trafficSource.source AS source,
        SUM(product.productRevenue)/1e6 AS monthly_revenue_millions
    FROM 
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits) AS hits,
        UNNEST(hits.product) AS product
    WHERE
        _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
        AND product.productRevenue IS NOT NULL
    GROUP BY 
        month, source
), max_daily AS (
    SELECT 
        MAX(daily_revenue_millions) AS max_daily_revenue
    FROM 
        daily_revenue
    WHERE 
        source = (SELECT source FROM source_revenue)
), max_weekly AS (
    SELECT 
        MAX(weekly_revenue_millions) AS max_weekly_revenue
    FROM 
        weekly_revenue
    WHERE 
        source = (SELECT source FROM source_revenue)
), max_monthly AS (
    SELECT 
        MAX(monthly_revenue_millions) AS max_monthly_revenue
    FROM 
        monthly_revenue
    WHERE 
        source = (SELECT source FROM source_revenue)
)
SELECT
    sr.source AS Traffic_Source,
    ROUND(sr.total_revenue_millions, 4) AS Total_Product_Revenue_in_millions,
    ROUND(md.max_daily_revenue, 4) AS Maximum_Daily_Revenue_in_millions,
    ROUND(mw.max_weekly_revenue, 4) AS Maximum_Weekly_Revenue_in_millions,
    ROUND(mm.max_monthly_revenue, 4) AS Maximum_Monthly_Revenue_in_millions
FROM 
    source_revenue sr
CROSS JOIN 
    max_daily md
CROSS JOIN 
    max_weekly mw
CROSS JOIN 
    max_monthly mm;