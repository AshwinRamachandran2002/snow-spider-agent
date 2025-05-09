WITH "CITY_STATS" AS (
    SELECT
        c."customer_city"                                              AS "city",
        SUM(p."payment_value")                                         AS "total_payment",
        COUNT(DISTINCT o."order_id")                                   AS "delivered_order_count"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"      o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS"   c
         ON o."customer_id" = c."customer_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" p
         ON o."order_id" = p."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_city"
),
"LOWEST_FIVE" AS (
    SELECT *
    FROM "CITY_STATS"
    ORDER BY "total_payment" ASC NULLS LAST
    LIMIT 5
)
SELECT
    ROUND(AVG("total_payment"), 4)          AS "avg_total_payment",
    ROUND(AVG("delivered_order_count"), 4)  AS "avg_delivered_order_count"
FROM "LOWEST_FIVE";