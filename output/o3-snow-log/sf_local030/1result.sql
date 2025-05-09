WITH
    "order_payments_sum" AS (
        SELECT
            "order_id",
            SUM("payment_value") AS "order_payment_value"
        FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS
        GROUP BY "order_id"
    ),

    "city_metrics" AS (
        SELECT
            c."customer_city"                       AS "city",
            SUM(op."order_payment_value")           AS "total_payments",
            COUNT(DISTINCT o."order_id")            AS "delivered_order_count"
        FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS            o
        JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS         c
              ON o."customer_id" = c."customer_id"
        JOIN "order_payments_sum"                                                     op
              ON o."order_id"   = op."order_id"
        WHERE o."order_status" = 'delivered'
        GROUP BY c."customer_city"
    ),

    "bottom5" AS (
        SELECT *
        FROM "city_metrics"
        ORDER BY "total_payments" ASC NULLS LAST
        LIMIT 5
    )

SELECT
    ROUND(AVG("total_payments"),          4) AS "avg_total_payments",
    ROUND(AVG("delivered_order_count"),   4) AS "avg_total_delivered_orders"
FROM "bottom5";