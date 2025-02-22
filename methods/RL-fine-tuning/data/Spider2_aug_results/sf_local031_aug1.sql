-- Task: Find the total number of delivered orders in each year from 2016 to 2018.

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
ORDER BY
    "Year" ASC;