SELECT
    o."customer_id",
    COUNT(DISTINCT o."order_id") AS "number_of_orders",
    ROUND(AVG(p."payment_value"), 4) AS "average_payment_per_order",
    ROUND(
        GREATEST(
            DATEDIFF('day', MIN(CAST(o."order_purchase_timestamp" AS TIMESTAMP)), MAX(CAST(o."order_purchase_timestamp" AS TIMESTAMP))) / 7.0,
            1.0
        ),
        2
    ) AS "customer_lifespan_in_weeks"
FROM
    "E_COMMERCE"."E_COMMERCE"."ORDERS" o
INNER JOIN
    "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS" p
    ON o."order_id" = p."order_id"
GROUP BY
    o."customer_id"
ORDER BY
    "average_payment_per_order" DESC NULLS LAST
LIMIT 3;