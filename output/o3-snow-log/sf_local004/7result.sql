WITH "order_payments_agg" AS (
    /* total paid for each order */
    SELECT
        "order_id",
        SUM("payment_value") AS "total_payment"
    FROM E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS"
    GROUP BY "order_id"
),
"orders_with_payment" AS (
    /* join orders to their total payments */
    SELECT
        o."customer_id",
        o."order_id",
        TO_DATE(o."order_purchase_timestamp")      AS "purchase_date",
        p."total_payment"
    FROM E_COMMERCE.E_COMMERCE."ORDERS" o
    JOIN "order_payments_agg" p
          ON o."order_id" = p."order_id"
),
"customer_stats" AS (
    /* aggregate per customer */
    SELECT
        "customer_id",
        COUNT(DISTINCT "order_id")                               AS "num_orders",
        AVG("total_payment")                                     AS "avg_payment_per_order",
        DATEDIFF('day', MIN("purchase_date"), MAX("purchase_date")) AS "diff_days"
    FROM "orders_with_payment"
    GROUP BY "customer_id"
)
SELECT
    "customer_id",
    "num_orders",
    ROUND("avg_payment_per_order", 4)                                            AS "avg_payment_per_order",
    /* lifespan in weeks, at least 1.0 */
    CASE 
        WHEN "diff_days" < 7 THEN 1.0
        ELSE ROUND("diff_days" / 7.0, 4)
    END                                                                          AS "customer_lifespan_weeks"
FROM "customer_stats"
ORDER BY "avg_payment_per_order" DESC NULLS LAST
LIMIT 3;