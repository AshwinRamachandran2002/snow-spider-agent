SELECT
    sub."customer_id",
    sub."number_of_orders",
    ROUND(sub."average_payment_per_order", 4) AS "average_payment_per_order",
    ROUND(
        CASE
            WHEN sub."lifespan_in_days" < 7 THEN 1.0
            ELSE sub."lifespan_in_days" / 7.0
        END,
    4) AS "customer_lifespan_in_weeks"
FROM
    (
        SELECT
            o."customer_id",
            COUNT(DISTINCT o."order_id") AS "number_of_orders",
            AVG(op_sum."total_order_payment") AS "average_payment_per_order",
            MIN(o."order_purchase_timestamp") AS "earliest_purchase_date",
            MAX(o."order_purchase_timestamp") AS "latest_purchase_date",
            DATEDIFF('day', MIN(o."order_purchase_timestamp"), MAX(o."order_purchase_timestamp")) AS "lifespan_in_days"
        FROM
            "E_COMMERCE"."E_COMMERCE"."ORDERS" o
            JOIN (
                SELECT
                    op."order_id",
                    SUM(op."payment_value") AS "total_order_payment"
                FROM
                    "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS" op
                GROUP BY
                    op."order_id"
            ) op_sum ON o."order_id" = op_sum."order_id"
        GROUP BY
            o."customer_id"
    ) sub
ORDER BY
    sub."average_payment_per_order" DESC NULLS LAST
LIMIT 3;