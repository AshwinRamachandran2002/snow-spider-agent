WITH order_totals AS (
    SELECT "order_id",
           SUM("payment_value") AS "order_total_payment"
    FROM "order_payments"
    GROUP BY "order_id"
),
customer_agg AS (
    SELECT  o."customer_id",
            COUNT(*)                                  AS "n_orders",
            AVG(ot."order_total_payment")             AS "avg_payment_per_order",
            MAX(o."order_purchase_timestamp")         AS "last_purchase",
            MIN(o."order_purchase_timestamp")         AS "first_purchase"
    FROM   "orders" AS o
    JOIN   order_totals AS ot
           ON ot."order_id" = o."order_id"
    GROUP  BY o."customer_id"
),
customer_final AS (
    SELECT
        "customer_id",
        "n_orders",
        ROUND("avg_payment_per_order", 4)             AS "avg_payment_per_order",
        CASE
            WHEN (JULIANDAY("last_purchase") - JULIANDAY("first_purchase")) < 7
                 THEN 1.0
            ELSE ROUND((JULIANDAY("last_purchase") - JULIANDAY("first_purchase")) / 7.0, 4)
        END                                           AS "lifespan_weeks"
    FROM   customer_agg
)
SELECT
    "customer_id",
    "n_orders",
    "avg_payment_per_order",
    "lifespan_weeks"
FROM   customer_final
ORDER  BY "avg_payment_per_order" DESC
LIMIT  3;