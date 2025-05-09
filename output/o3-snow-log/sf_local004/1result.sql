WITH "PAYMENT_PER_ORDER" AS (
    /* total paid value for each order */
    SELECT 
        op."order_id",
        SUM(op."payment_value") AS "order_payment"
    FROM E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS" op
    GROUP BY op."order_id"
),
"ORDERS_PAYMENTS" AS (
    /* join orders to their total payment */
    SELECT 
        o."customer_id",
        o."order_id",
        TO_TIMESTAMP(o."order_purchase_timestamp")     AS "order_purchase_ts",
        p."order_payment"
    FROM E_COMMERCE.E_COMMERCE."ORDERS" o
    JOIN "PAYMENT_PER_ORDER" p
      ON o."order_id" = p."order_id"
),
"CUSTOMER_STATS" AS (
    /* required metrics for each customer */
    SELECT
        "customer_id",
        COUNT("order_id")                                AS "number_of_orders",
        AVG("order_payment")                             AS "avg_payment_per_order",
        CASE 
             WHEN DATEDIFF('day',
                           MIN("order_purchase_ts"),
                           MAX("order_purchase_ts")) < 7
             THEN 1.0
             ELSE DATEDIFF('day',
                            MIN("order_purchase_ts"),
                            MAX("order_purchase_ts")) / 7.0
        END                                              AS "lifespan_weeks"
    FROM "ORDERS_PAYMENTS"
    GROUP BY "customer_id"
)
SELECT 
    "customer_id",
    "number_of_orders",
    ROUND("avg_payment_per_order", 4)  AS "average_payment_per_order",
    ROUND("lifespan_weeks", 4)         AS "customer_lifespan_weeks"
FROM "CUSTOMER_STATS"
ORDER BY "average_payment_per_order" DESC NULLS LAST
LIMIT 3;