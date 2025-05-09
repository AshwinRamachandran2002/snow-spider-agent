WITH Yearly_Delivered_Orders AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
        COUNT(*) AS "Total_Delivered_Orders"
    FROM
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE
        "order_status" = 'delivered'
        AND "order_delivered_customer_date" IS NOT NULL
        AND "order_delivered_customer_date" <> ''
        AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) IN (2016, 2017, 2018)
    GROUP BY
        "Year"
),
Min_Year AS (
    SELECT
        "Year"
    FROM
        Yearly_Delivered_Orders
    ORDER BY
        "Total_Delivered_Orders" ASC NULLS LAST
    LIMIT 1
)
SELECT
    COUNT(*) AS "Highest_Monthly_Delivered_Orders_Volume",
    TO_VARCHAR(EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS'))) AS "Month",
    TO_VARCHAR(EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS'))) AS "Year"
FROM
    BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
WHERE
    "order_status" = 'delivered'
        AND "order_delivered_customer_date" IS NOT NULL
        AND "order_delivered_customer_date" <> ''
        AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) = (SELECT "Year" FROM Min_Year)
GROUP BY
    "Year", "Month"
ORDER BY
    "Highest_Monthly_Delivered_Orders_Volume" DESC NULLS LAST
LIMIT 1;