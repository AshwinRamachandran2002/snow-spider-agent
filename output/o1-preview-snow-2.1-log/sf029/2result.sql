WITH daily_data AS (
    SELECT
        s."DATE" AS "Date",
        s."ASIN",
        s."PRODUCT_TITLE" AS "Product_Title",
        s."ORDERED_UNITS",
        s."ORDERED_REVENUE",
        ROUND(s."ORDERED_REVENUE" / NULLIF(s."ORDERED_UNITS", 0), 4) AS "Average_Selling_Price_ASP",
        t."GLANCE_VIEWS",
        ROUND(s."ORDERED_UNITS" / NULLIF(t."GLANCE_VIEWS", 0), 4) AS "Conversion_Rate",
        s."SHIPPED_UNITS",
        s."SHIPPED_REVENUE",
        ROUND(n."NET_PPM", 4) AS "Net_Profit_Margin_PPM",
        i."SELLABLE_ON_HAND_UNITS" AS "Inventory_Details"
    FROM
        AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_SALES s
        LEFT JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_TRAFFIC t
            ON s."ASIN" = t."ASIN"
            AND s."DATE" = t."DATE"
            AND t."DISTRIBUTOR_VIEW" = 'Manufacturing'
        LEFT JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_NET_PPM n
            ON s."ASIN" = n."ASIN"
            AND s."DATE" = n."DATE"
            AND n."DISTRIBUTOR_VIEW" = 'Manufacturing'
        LEFT JOIN AMAZON_VENDOR_ANALYTICS__SAMPLE_DATASET.PUBLIC.RETAIL_ANALYTICS_INVENTORY i
            ON s."ASIN" = i."ASIN"
            AND s."DATE" = i."DATE"
            AND i."DISTRIBUTOR_VIEW" = 'Manufacturing'
    WHERE
        s."DATE" BETWEEN '2022-01-07' AND '2022-02-06'
        AND s."DISTRIBUTOR_VIEW" = 'Manufacturing'
)
SELECT
    dd."Date",
    dd."ASIN",
    dd."Product_Title",
    dd."ORDERED_UNITS",
    dd."ORDERED_REVENUE",
    dd."Average_Selling_Price_ASP",
    dd."GLANCE_VIEWS",
    dd."Conversion_Rate",
    dd."SHIPPED_UNITS",
    dd."SHIPPED_REVENUE",
    dd."Net_Profit_Margin_PPM",
    dd."Inventory_Details",
    SUM(dd."ORDERED_UNITS") OVER (PARTITION BY dd."ASIN") AS "Total_Ordered_Units",
    ROUND(AVG(dd."ORDERED_UNITS") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Ordered_Units",
    SUM(dd."ORDERED_REVENUE") OVER (PARTITION BY dd."ASIN") AS "Total_Ordered_Revenue",
    ROUND(AVG(dd."ORDERED_REVENUE") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Ordered_Revenue",
    ROUND(AVG(dd."Average_Selling_Price_ASP") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Selling_Price_ASP_Avg",
    SUM(dd."GLANCE_VIEWS") OVER (PARTITION BY dd."ASIN") AS "Total_Glance_Views",
    ROUND(AVG(dd."GLANCE_VIEWS") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Glance_Views",
    ROUND(AVG(dd."Conversion_Rate") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Conversion_Rate",
    SUM(dd."SHIPPED_UNITS") OVER (PARTITION BY dd."ASIN") AS "Total_Shipped_Units",
    ROUND(AVG(dd."SHIPPED_UNITS") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Shipped_Units",
    SUM(dd."SHIPPED_REVENUE") OVER (PARTITION BY dd."ASIN") AS "Total_Shipped_Revenue",
    ROUND(AVG(dd."SHIPPED_REVENUE") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Shipped_Revenue",
    ROUND(AVG(dd."Net_Profit_Margin_PPM") OVER (PARTITION BY dd."ASIN"), 4) AS "Average_Net_Profit_Margin_PPM"
FROM
    daily_data dd
ORDER BY
    dd."Date", dd."ASIN";