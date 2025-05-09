WITH top_customers AS (
    /* 1. Top-10 customers by total amount paid */
    SELECT
        "customer_id",
        SUM("amount") AS total_amount
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
    ORDER BY total_amount DESC NULLS LAST
    LIMIT 10
),
monthly_totals AS (
    /* 2. Monthly payment totals for those customers */
    SELECT
        p."customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date")) AS month_start,
        SUM(p."amount") AS month_amount
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    JOIN top_customers tc
      ON p."customer_id" = tc."customer_id"
    GROUP BY
        p."customer_id",
        month_start
),
month_diffs AS (
    /* 3. Month-over-month differences */
    SELECT
        "customer_id",
        month_start,
        month_amount,
        LEAD(month_amount) OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start
        ) AS next_month_amount
    FROM monthly_totals
),
max_diff AS (
    /* 4. Absolute differences rounded to two decimals */
    SELECT
        "customer_id",
        TO_CHAR(month_start, 'YYYY-MM') AS month,
        ROUND(ABS(next_month_amount - month_amount), 2) AS amount_difference
    FROM month_diffs
    WHERE next_month_amount IS NOT NULL
)
/* 5. Largest month-to-month jump among the top 10 customers */
SELECT
    "customer_id",
    month,
    amount_difference
FROM max_diff
ORDER BY amount_difference DESC NULLS LAST
LIMIT 1;