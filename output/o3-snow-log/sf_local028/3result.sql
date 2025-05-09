WITH delivered_orders AS (
    SELECT
        TO_DATE(TRY_TO_TIMESTAMP("order_delivered_customer_date")) AS delivered_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
          AND "order_delivered_customer_date" IS NOT NULL
          AND YEAR(TRY_TO_TIMESTAMP("order_delivered_customer_date")) IN (2016, 2017, 2018)
)
SELECT
       LPAD(MONTH(delivered_date), 2, '0') || ' - ' || TO_CHAR(delivered_date, 'Mon') AS "MONTH",
       SUM(CASE WHEN YEAR(delivered_date) = 2016 THEN 1 ELSE 0 END) AS "2016",
       SUM(CASE WHEN YEAR(delivered_date) = 2017 THEN 1 ELSE 0 END) AS "2017",
       SUM(CASE WHEN YEAR(delivered_date) = 2018 THEN 1 ELSE 0 END) AS "2018"
FROM delivered_orders
GROUP BY MONTH(delivered_date), TO_CHAR(delivered_date, 'Mon')
ORDER BY MONTH(delivered_date);