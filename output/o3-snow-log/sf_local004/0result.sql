WITH "payments_per_order" AS (
    SELECT
        op."order_id",
        SUM(op."payment_value") AS "payment_value"
    FROM E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS" op
    GROUP BY op."order_id"
),
"orders_with_payment" AS (
    SELECT
        o."customer_id",
        o."order_id",
        p."payment_value",
        TO_TIMESTAMP(o."order_purchase_timestamp") AS "purchase_ts"
    FROM E_COMMERCE.E_COMMERCE."ORDERS" o
    JOIN "payments_per_order" p
      ON o."order_id" = p."order_id"
),
"customer_metrics" AS (
    SELECT
        ow."customer_id",
        COUNT(DISTINCT ow."order_id")                              AS "number_of_orders",
        AVG(ow."payment_value")                                    AS "avg_payment",
        DATEDIFF('day', MIN(ow."purchase_ts"), MAX(ow."purchase_ts")) AS "days_span"
    FROM "orders_with_payment" ow
    GROUP BY ow."customer_id"
),
"final_metrics" AS (
    SELECT
        cm."customer_id",
        cm."number_of_orders",
        ROUND(cm."avg_payment", 4)                                            AS "average_payment_per_order",
        ROUND(
            CASE 
                WHEN cm."days_span" < 7 THEN 1.0
                ELSE cm."days_span" / 7.0
            END
        , 4)                                                                  AS "lifespan_weeks"
    FROM "customer_metrics" cm
)
SELECT
    "customer_id",
    "number_of_orders",
    "average_payment_per_order",
    "lifespan_weeks"
FROM "final_metrics"
ORDER BY "average_payment_per_order" DESC NULLS LAST
LIMIT 3;