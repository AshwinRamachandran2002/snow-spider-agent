SELECT
    TRIM(TO_CHAR(TO_DATE('2000-' || "month_num" || '-01', 'YYYY-MM-DD'), 'Month')) AS "Month",
    SUM(CASE WHEN "Year" = 2016 THEN num_orders ELSE 0 END) AS "2016",
    SUM(CASE WHEN "Year" = 2017 THEN num_orders ELSE 0 END) AS "2017",
    SUM(CASE WHEN "Year" = 2018 THEN num_orders ELSE 0 END) AS "2018"
FROM (
    SELECT
        EXTRACT(MONTH FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS "month_num",
        EXTRACT(YEAR FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
        1 AS num_orders
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE
        "order_status" = 'delivered' AND
        "order_delivered_customer_date" IS NOT NULL AND
        "order_delivered_customer_date" != '' AND
        TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL AND
        EXTRACT(YEAR FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) IN (2016, 2017, 2018)
) sub
GROUP BY "month_num"
ORDER BY "month_num";