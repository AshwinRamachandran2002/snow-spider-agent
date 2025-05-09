SELECT
    sub."customer_id",
    sub."order_count",
    sub."average_payment_per_order",
    sub."customer_lifespan_weeks"
FROM (
    SELECT
        o."customer_id",
        COUNT(DISTINCT o."order_id")                                        AS "order_count",
        ROUND(SUM(p."payment_value") / COUNT(DISTINCT o."order_id"), 4)     AS "average_payment_per_order",
        CASE
            WHEN (julianday(MAX(o."order_purchase_timestamp")) -
                  julianday(MIN(o."order_purchase_timestamp"))) / 7.0 < 1
            THEN ROUND(1.0, 4)
            ELSE ROUND(
                (julianday(MAX(o."order_purchase_timestamp")) -
                 julianday(MIN(o."order_purchase_timestamp"))) / 7.0, 4)
        END                                                                 AS "customer_lifespan_weeks"
    FROM "orders" o
    JOIN "order_payments" p
      ON p."order_id" = o."order_id"
    GROUP BY o."customer_id"
) sub
ORDER BY sub."average_payment_per_order" DESC, sub."customer_id"
LIMIT 3;