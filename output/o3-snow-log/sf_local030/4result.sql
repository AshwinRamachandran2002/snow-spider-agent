WITH delivered_orders AS (
    SELECT 
        o."order_id",
        c."customer_city"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS" o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),
city_payments AS (
    SELECT
        d."customer_city"                                    AS "city",
        SUM(p."payment_value")                               AS "total_payment",
        COUNT(DISTINCT d."order_id")                         AS "delivered_orders"
    FROM delivered_orders d
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" p
          ON d."order_id" = p."order_id"
    GROUP BY d."customer_city"
),
lowest_five AS (
    SELECT *
    FROM city_payments
    ORDER BY "total_payment" ASC NULLS LAST
    LIMIT 5
)
SELECT
    ROUND(AVG("total_payment"), 4)      AS "AVG_TOTAL_PAYMENT",
    ROUND(AVG("delivered_orders"), 4)   AS "AVG_DELIVERED_ORDER_COUNT"
FROM lowest_five;