WITH top_customers AS (
    SELECT "customer_id"
    FROM "payment"
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC
    LIMIT 10
),
monthly_payments AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "payment_date") AS "month",
        SUM("amount") AS "monthly_payment"
    FROM "payment"
    WHERE "customer_id" IN (SELECT "customer_id" FROM top_customers)
    GROUP BY "customer_id", "month"
),
payment_differences AS (
    SELECT
        "customer_id",
        "monthly_payment",
        "monthly_payment" - LAG("monthly_payment") OVER (PARTITION BY "customer_id" ORDER BY "month") AS "payment_difference"
    FROM monthly_payments
),
max_differences AS (
    SELECT
        "customer_id",
        MAX(ABS("payment_difference")) AS "highest_payment_difference"
    FROM payment_differences
    GROUP BY "customer_id"
),
max_customer AS (
    SELECT
        "customer_id",
        "highest_payment_difference"
    FROM max_differences
    ORDER BY "highest_payment_difference" DESC
    LIMIT 1
)
SELECT
    c."customer_id",
    c."first_name" || ' ' || c."last_name" AS "customer_name",
    ROUND(m."highest_payment_difference", 4) AS "highest_payment_difference"
FROM
    max_customer m
    JOIN "customer" c ON m."customer_id" = c."customer_id";