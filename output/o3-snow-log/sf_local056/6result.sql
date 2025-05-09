WITH monthly_payments AS (
    SELECT
        "customer_id",
        DATE_TRUNC('MONTH', TO_TIMESTAMP("payment_date"))      AS month_start,
        SUM("amount")                                          AS monthly_total
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY
        "customer_id",
        month_start
),
payment_changes AS (
    SELECT
        "customer_id",
        month_start,
        monthly_total,
        ABS(monthly_total - LAG(monthly_total) 
            OVER (PARTITION BY "customer_id" ORDER BY month_start)) AS change_value
    FROM monthly_payments
),
avg_change_per_customer AS (
    SELECT
        "customer_id",
        AVG(change_value) AS avg_monthly_change
    FROM payment_changes
    WHERE change_value IS NOT NULL
    GROUP BY "customer_id"
),
top_customer AS (
    SELECT "customer_id"
    FROM avg_change_per_customer
    ORDER BY avg_monthly_change DESC NULLS LAST
    LIMIT 1
)
SELECT
    c."first_name" || ' ' || c."last_name" AS "full_name"
FROM SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER AS c
JOIN top_customer AS t
  ON c."customer_id" = t."customer_id";