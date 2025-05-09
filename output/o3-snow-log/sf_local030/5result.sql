WITH "CITY_PAYMENTS" AS (
    SELECT 
        C."customer_city"                         AS "city",
        SUM(P."payment_value")                    AS "total_payments",
        COUNT(DISTINCT O."order_id")              AS "delivered_orders"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"            O
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS"         C
         ON O."customer_id" = C."customer_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"    P
         ON O."order_id" = P."order_id"
    WHERE O."order_status" = 'delivered'
    GROUP BY C."customer_city"
), 
"LOWEST_FIVE_CITIES" AS (
    SELECT *
    FROM "CITY_PAYMENTS"
    ORDER BY "total_payments" ASC NULLS LAST
    LIMIT 5
)
SELECT 
    ROUND(AVG("total_payments"), 4)    AS "avg_total_payments",
    ROUND(AVG("delivered_orders"), 4)  AS "avg_delivered_order_counts"
FROM "LOWEST_FIVE_CITIES";