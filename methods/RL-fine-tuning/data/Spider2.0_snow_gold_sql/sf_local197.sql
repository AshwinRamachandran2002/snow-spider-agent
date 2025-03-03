WITH top_customers AS (
    SELECT "customer_id", SUM("amount") AS "total_amount"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT"
    GROUP BY "customer_id"
    ORDER BY "total_amount" DESC
    LIMIT 10
),
monthly_payments AS (
    SELECT "customer_id", SUBSTRING("payment_date", 1, 7) AS "month", SUM("amount") AS "monthly_total"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT"
    GROUP BY "customer_id", SUBSTRING("payment_date", 1, 7)
),
payment_differences AS (
    SELECT "customer_id", "month",
        "monthly_total" - LAG("monthly_total", 1, 0) OVER (PARTITION BY "customer_id" ORDER BY "month") AS "payment_difference"
    FROM monthly_payments
),
max_payment_difference AS (
    SELECT "customer_id", MAX(ABS("payment_difference")) AS "max_payment_difference"
    FROM payment_differences
    GROUP BY "customer_id"
),
customer_info AS (
    SELECT tc."customer_id", c."first_name" || ' ' || c."last_name" AS "Customer_Name", ROUND(md."max_payment_difference", 4) AS "Highest_Payment_Difference"
    FROM top_customers tc
    JOIN max_payment_difference md ON tc."customer_id" = md."customer_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."CUSTOMER" c ON tc."customer_id" = c."customer_id"
)
SELECT "Customer_Name", "Highest_Payment_Difference"
FROM customer_info
ORDER BY "Highest_Payment_Difference" DESC NULLS LAST
LIMIT 1;