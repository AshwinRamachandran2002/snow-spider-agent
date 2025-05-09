WITH top_customers AS (      -- 1. ten biggest spenders overall
    SELECT
        "customer_id",
        SUM("amount") AS total_paid
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
    ORDER BY total_paid DESC NULLS LAST
    LIMIT 10
),
monthly_totals AS (          -- 2. monthly spend for those customers
    SELECT
        p."customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date")) AS pay_month,
        SUM(p."amount") AS month_total
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    JOIN top_customers tc
      ON tc."customer_id" = p."customer_id"
    GROUP BY p."customer_id", pay_month
),
month_over_month AS (        -- 3. month-over-month difference
    SELECT
        "customer_id",
        pay_month,
        month_total,
        LAG(month_total) OVER (PARTITION BY "customer_id" ORDER BY pay_month) AS prev_month_total,
        ABS(month_total - LAG(month_total) OVER (PARTITION BY "customer_id" ORDER BY pay_month)) AS diff_amount
    FROM monthly_totals
)
-- 4. pick the largest change
SELECT
    "customer_id",
    TO_CHAR(pay_month, 'YYYY-MM')       AS "month",
    ROUND(diff_amount, 2)               AS "month_over_month_difference"
FROM month_over_month
WHERE diff_amount IS NOT NULL
ORDER BY diff_amount DESC NULLS LAST
LIMIT 1;