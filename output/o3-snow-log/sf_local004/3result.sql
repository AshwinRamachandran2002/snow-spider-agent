WITH "order_payments_agg" AS (
    /* total payment value for every order                                   */
    SELECT 
        "order_id",
        SUM("payment_value") AS "order_payment_total"
    FROM E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS"
    GROUP BY "order_id"
),
"orders_with_payment" AS (
    /* orders enriched with their total payment value                        */
    SELECT
        o."customer_id",
        o."order_id",
        o."order_purchase_timestamp",
        p."order_payment_total"
    FROM E_COMMERCE.E_COMMERCE."ORDERS"              o
    JOIN "order_payments_agg"                        p
          ON o."order_id" = p."order_id"
),
"customer_stats" AS (
    /* metrics required per customer                                         */
    SELECT
        "customer_id",
        COUNT(DISTINCT "order_id")                                          AS "number_of_orders",
        AVG("order_payment_total")                                          AS "avg_payment_per_order",
        /* lifespan in weeks (≥1.0)                                           */
        CASE 
            WHEN DATEDIFF('day',
                          MIN(TO_TIMESTAMP("order_purchase_timestamp")),
                          MAX(TO_TIMESTAMP("order_purchase_timestamp"))) < 7
            THEN 1.0
            ELSE DATEDIFF('day',
                           MIN(TO_TIMESTAMP("order_purchase_timestamp")),
                           MAX(TO_TIMESTAMP("order_purchase_timestamp"))) / 7.0
        END                                                                AS "customer_lifespan_weeks"
    FROM "orders_with_payment"
    GROUP BY "customer_id"
)
SELECT
    "customer_id",
    "number_of_orders",
    ROUND("avg_payment_per_order",     4)  AS "avg_payment_per_order",
    ROUND("customer_lifespan_weeks",   4)  AS "customer_lifespan_weeks"
FROM "customer_stats"
ORDER BY "avg_payment_per_order" DESC NULLS LAST
LIMIT 3;