WITH "ORDER_PAYMENTS_TOTALS" AS (
    SELECT 
        "order_id",
        SUM("payment_value") AS "order_total_payment"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS
    GROUP BY "order_id"
),
"DELIVERED_ORDERS" AS (
    SELECT 
        o."order_id",
        o."customer_id",
        p."order_total_payment"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o
    JOIN "ORDER_PAYMENTS_TOTALS" p
        ON o."order_id" = p."order_id"
    WHERE o."order_status" = 'delivered'
),
"ORDERS_WITH_CITY" AS (
    SELECT
        d."order_id",
        c."customer_city",
        d."order_total_payment"
    FROM "DELIVERED_ORDERS" d
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS c
        ON d."customer_id" = c."customer_id"
),
"CITY_METRICS" AS (
    SELECT
        "customer_city",
        SUM("order_total_payment") AS "total_payment",
        COUNT(*) AS "delivered_order_count"
    FROM "ORDERS_WITH_CITY"
    GROUP BY "customer_city"
),
"LOWEST_FIVE" AS (
    SELECT *
    FROM "CITY_METRICS"
    ORDER BY "total_payment" ASC NULLS LAST
    FETCH FIRST 5 ROWS ONLY
)
SELECT 
    ROUND(AVG("total_payment"), 4)          AS "avg_of_total_payments",
    ROUND(AVG("delivered_order_count"), 4)  AS "avg_of_delivered_order_counts"
FROM "LOWEST_FIVE";