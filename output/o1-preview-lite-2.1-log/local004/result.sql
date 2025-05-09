WITH order_total_payments AS (
    SELECT
        "order_id",
        SUM("payment_value") AS "total_payment"
    FROM
        "order_payments"
    GROUP BY
        "order_id"
),
customer_payments AS (
    SELECT
        o."customer_id",
        COUNT(DISTINCT o."order_id") AS "number_of_orders",
        AVG(otp."total_payment") AS "average_payment_per_order",
        MIN(o."order_purchase_timestamp") AS "first_order_date",
        MAX(o."order_purchase_timestamp") AS "last_order_date"
    FROM
        "orders" o
        JOIN order_total_payments otp ON o."order_id" = otp."order_id"
    WHERE
        o."order_purchase_timestamp" IS NOT NULL
    GROUP BY
        o."customer_id"
),
customer_lifespans AS (
    SELECT
        cp."customer_id",
        cp."number_of_orders",
        cp."average_payment_per_order",
        CASE
            WHEN (julianday(cp."last_order_date") - julianday(cp."first_order_date")) >= 7.0 THEN
                (julianday(cp."last_order_date") - julianday(cp."first_order_date")) / 7.0
            ELSE
                1.0
        END AS "customer_lifespan_weeks"
    FROM
        customer_payments cp
)
SELECT
    cl."customer_id",
    cl."number_of_orders",
    printf('%.4f', cl."average_payment_per_order") AS "average_payment_per_order",
    printf('%.4f', cl."customer_lifespan_weeks") AS "customer_lifespan_weeks"
FROM
    customer_lifespans cl
ORDER BY
    cl."average_payment_per_order" DESC
LIMIT 3;