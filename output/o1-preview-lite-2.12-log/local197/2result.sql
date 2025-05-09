WITH top_customers AS (
    SELECT "customer_id", SUM("amount") AS total_paid
    FROM "payment"
    GROUP BY "customer_id"
    ORDER BY total_paid DESC
    LIMIT 10
),
monthly_totals AS (
    SELECT p."customer_id", strftime('%Y-%m', p."payment_date") AS month, SUM(p."amount") AS monthly_total
    FROM "payment" p
    GROUP BY p."customer_id", month
),
top_customers_monthly AS (
    SELECT m.*
    FROM monthly_totals m
    JOIN top_customers t ON m."customer_id" = t."customer_id"
),
payment_differences AS (
    SELECT "customer_id", MAX(monthly_total) - MIN(monthly_total) AS payment_difference
    FROM top_customers_monthly
    GROUP BY "customer_id"
),
max_payment_difference_customer AS (
    SELECT "customer_id", payment_difference
    FROM payment_differences
    ORDER BY payment_difference DESC
    LIMIT 1
),
customer_info AS (
    SELECT c."customer_id", c."first_name" || ' ' || c."last_name" AS customer_name
    FROM "customer" c
)

SELECT m."customer_id", ci.customer_name, ROUND(m.payment_difference, 2) AS highest_payment_difference
FROM max_payment_difference_customer m
JOIN customer_info ci ON m."customer_id" = ci."customer_id";