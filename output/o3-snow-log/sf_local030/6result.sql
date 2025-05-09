WITH "DELIVERED_ORDERS" AS (
    SELECT 
        o."order_id",
        c."customer_city"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"  o
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),

"CITY_AGGREGATES" AS (
    SELECT
        d."customer_city"                                          AS "city",
        SUM(p."payment_value")                                     AS "total_payment",
        COUNT(DISTINCT d."order_id")                               AS "delivered_order_count"
    FROM "DELIVERED_ORDERS" d
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" p
          ON d."order_id" = p."order_id"
    GROUP BY d."customer_city"
),

"BOTTOM_FIVE" AS (
    SELECT *
    FROM "CITY_AGGREGATES"
    ORDER BY "total_payment" ASC NULLS LAST
    LIMIT 5
)

SELECT
    AVG("total_payment")          AS "avg_of_lowest_five_total_payments",
    AVG("delivered_order_count")  AS "avg_of_lowest_five_order_counts"
FROM "BOTTOM_FIVE";