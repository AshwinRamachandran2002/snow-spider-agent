/*  Number of delivered orders per month for the years 2016-2018  */
WITH delivered_orders AS (
    SELECT
        TO_DATE("order_purchase_timestamp") AS purchase_date
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE LOWER("order_status") = 'delivered'
      AND TO_DATE("order_purchase_timestamp") >= '2016-01-01'
      AND TO_DATE("order_purchase_timestamp") <  '2019-01-01'
)

SELECT
    MONTH(purchase_date)                                            AS "MONTH",
    SUM(CASE WHEN YEAR(purchase_date) = 2016 THEN 1 ELSE 0 END)     AS "2016",
    SUM(CASE WHEN YEAR(purchase_date) = 2017 THEN 1 ELSE 0 END)     AS "2017",
    SUM(CASE WHEN YEAR(purchase_date) = 2018 THEN 1 ELSE 0 END)     AS "2018"
FROM delivered_orders
GROUP BY "MONTH"
ORDER BY "MONTH";