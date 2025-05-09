WITH "order_payments_total" AS (             -- total paid per order
    SELECT
        "order_id",
        SUM("payment_value") AS "order_payment_total"
    FROM E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS"
    GROUP BY "order_id"
),
"customer_orders" AS (                       -- orders & basic sums per customer
    SELECT
        o."customer_id",
        COUNT(DISTINCT o."order_id")                         AS "number_orders",
        SUM(opt."order_payment_total")                       AS "total_payments",
        MIN(TO_TIMESTAMP_NTZ(o."order_purchase_timestamp"))  AS "first_purchase",
        MAX(TO_TIMESTAMP_NTZ(o."order_purchase_timestamp"))  AS "last_purchase"
    FROM E_COMMERCE.E_COMMERCE."ORDERS" o
    JOIN "order_payments_total" opt
          ON o."order_id" = opt."order_id"
    GROUP BY o."customer_id"
),
"customer_metrics" AS (                      -- final metrics
    SELECT
        "customer_id",
        "number_orders",
        "total_payments" / "number_orders"                                   AS "avg_payment_per_order",
        CASE
            WHEN DATEDIFF('day', "first_purchase", "last_purchase") < 7
                 THEN 1.0
            ELSE DATEDIFF('day', "first_purchase", "last_purchase") / 7.0
        END                                                                  AS "lifespan_weeks"
    FROM "customer_orders"
)
SELECT
    "customer_id",
    "number_orders"                     AS "number_of_orders",
    ROUND("avg_payment_per_order", 4)   AS "average_payment_per_order",
    ROUND("lifespan_weeks", 4)          AS "customer_lifespan_weeks"
FROM "customer_metrics"
ORDER BY "avg_payment_per_order" DESC NULLS LAST
LIMIT 3;