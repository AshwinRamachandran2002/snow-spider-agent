WITH payments_monthly AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("payment_date")) AS month_start,
        SUM("amount") AS month_total
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id", DATE_TRUNC('month', TO_TIMESTAMP_NTZ("payment_date"))
),
monthly_changes AS (
    SELECT
        "customer_id",
        month_total,
        month_start,
        ABS(month_total 
            - LAG(month_total) OVER (PARTITION BY "customer_id" ORDER BY month_start)
        ) AS change_amt
    FROM payments_monthly
),
avg_changes AS (
    SELECT
        "customer_id",
        AVG(change_amt) AS avg_monthly_change
    FROM monthly_changes
    WHERE change_amt IS NOT NULL
    GROUP BY "customer_id"
),
top_customer AS (
    SELECT
        "customer_id",
        avg_monthly_change
    FROM avg_changes
    ORDER BY avg_monthly_change DESC NULLS LAST
    LIMIT 1
)
SELECT
    CONCAT_WS(' ', c."first_name", c."last_name") AS "full_name"
FROM top_customer tc
JOIN SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
  ON c."customer_id" = tc."customer_id";