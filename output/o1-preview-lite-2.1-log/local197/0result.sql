WITH top_customers AS (
    SELECT "customer_id", SUM("amount") AS "total_payments"
    FROM "payment"
    GROUP BY "customer_id"
    ORDER BY "total_payments" DESC
    LIMIT 10
),
monthly_totals AS (
    SELECT
        "customer_id",
        STRFTIME('%Y-%m', "payment_date") AS "payment_month",
        SUM("amount") AS "monthly_total"
    FROM "payment"
    WHERE "customer_id" IN (SELECT "customer_id" FROM top_customers)
    GROUP BY "customer_id", "payment_month"
),
payment_differences AS (
    SELECT
        "customer_id",
        MAX("monthly_total") - MIN("monthly_total") AS "payment_difference"
    FROM monthly_totals
    GROUP BY "customer_id"
),
max_difference_customer AS (
    SELECT
        "customer_id",
        "payment_difference"
    FROM payment_differences
    ORDER BY "payment_difference" DESC
    LIMIT 1
)
SELECT
    c."customer_id",
    c."first_name" || ' ' || c."last_name" AS "customer_name",
    ROUND(mdc."payment_difference", 4) AS "highest_payment_difference"
FROM max_difference_customer mdc
JOIN "customer" c ON c."customer_id" = mdc."customer_id"