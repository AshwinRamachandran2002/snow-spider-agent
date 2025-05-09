/* Delivered orders per month (2016-2018) */
WITH delivered_orders AS (
    SELECT
        TRY_TO_DATE("order_delivered_customer_date") AS delivered_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
)

SELECT
       TO_CHAR(delivered_date, 'Mon')                                            AS "Month",
       SUM(CASE WHEN YEAR(delivered_date) = 2016 THEN 1 ELSE 0 END)             AS "2016",
       SUM(CASE WHEN YEAR(delivered_date) = 2017 THEN 1 ELSE 0 END)             AS "2017",
       SUM(CASE WHEN YEAR(delivered_date) = 2018 THEN 1 ELSE 0 END)             AS "2018"
FROM delivered_orders
WHERE delivered_date IS NOT NULL
  AND YEAR(delivered_date) BETWEEN 2016 AND 2018
GROUP BY MONTH(delivered_date), TO_CHAR(delivered_date, 'Mon')
ORDER BY MONTH(delivered_date);