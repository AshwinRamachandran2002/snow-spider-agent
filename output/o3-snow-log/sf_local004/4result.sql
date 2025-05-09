WITH order_totals AS (
    SELECT 
        op."order_id",
        SUM(op."payment_value") AS order_total_payment
    FROM E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS op
    GROUP BY op."order_id"
),
orders_payments AS (
    SELECT 
        o."customer_id",
        o."order_id",
        o."order_purchase_timestamp",
        ot.order_total_payment
    FROM E_COMMERCE.E_COMMERCE.ORDERS o
    JOIN order_totals ot
      ON o."order_id" = ot."order_id"
),
customer_metrics AS (
    SELECT
        op."customer_id",
        COUNT(*) AS num_orders,
        ROUND(AVG(op.order_total_payment), 4) AS avg_payment_per_order,
        ROUND(
            CASE 
                WHEN DATEDIFF('day', MIN(op."order_purchase_timestamp"), MAX(op."order_purchase_timestamp")) < 7
                    THEN 1.0
                ELSE DATEDIFF('day', MIN(op."order_purchase_timestamp"), MAX(op."order_purchase_timestamp")) / 7.0
            END
        , 4) AS lifespan_weeks
    FROM orders_payments op
    GROUP BY op."customer_id"
)
SELECT
    "customer_id",
    num_orders AS "number_of_orders",
    avg_payment_per_order AS "average_payment_per_order",
    lifespan_weeks AS "customer_lifespan_weeks"
FROM customer_metrics
ORDER BY avg_payment_per_order DESC NULLS LAST
LIMIT 3;