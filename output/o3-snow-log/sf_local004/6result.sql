WITH "payments_per_order" AS (
    SELECT
        op."order_id",
        SUM(op."payment_value") AS "order_payment"
    FROM "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS" op
    GROUP BY op."order_id"
),
"customer_orders" AS (
    SELECT
        c."customer_unique_id",
        o."order_id",
        o."order_purchase_timestamp",
        p."order_payment"
    FROM "E_COMMERCE"."E_COMMERCE"."ORDERS"   o
    JOIN "E_COMMERCE"."E_COMMERCE"."CUSTOMERS" c
          ON o."customer_id" = c."customer_id"
    JOIN "payments_per_order"                  p
          ON o."order_id" = p."order_id"
),
"aggregated" AS (
    SELECT
        "customer_unique_id",
        COUNT(DISTINCT "order_id")                        AS "num_orders",
        AVG("order_payment")                              AS "avg_payment_per_order",
        MIN("order_purchase_timestamp")                   AS "first_purchase",
        MAX("order_purchase_timestamp")                   AS "last_purchase"
    FROM "customer_orders"
    GROUP BY "customer_unique_id"
)
SELECT
    "customer_unique_id",
    "num_orders",
    ROUND("avg_payment_per_order", 4)                    AS "avg_payment_per_order",
    CASE
        WHEN DATEDIFF('day', "first_purchase", "last_purchase") < 7
             THEN 1.0
        ELSE ROUND(DATEDIFF('day', "first_purchase", "last_purchase") / 7.0, 4)
    END                                                  AS "customer_lifespan_weeks"
FROM "aggregated"
ORDER BY "avg_payment_per_order" DESC NULLS LAST
LIMIT 3;