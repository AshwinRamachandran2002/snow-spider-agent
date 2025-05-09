WITH top_customers AS (      -- 1. ten customers who have paid the most in total
    SELECT "customer_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC NULLS LAST
    LIMIT 10
),
monthly_totals AS (          -- 2. monthly payment totals for those customers
    SELECT
        "customer_id",
        DATE_TRUNC('MONTH', TO_TIMESTAMP("payment_date"))         AS month_start,
        SUM("amount")                                            AS month_total
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    WHERE "customer_id" IN (SELECT "customer_id" FROM top_customers)
    GROUP BY "customer_id", month_start
),
month_over_month AS (        -- 3. month-over-month change per customer
    SELECT
        "customer_id",
        month_start,
        month_total
            - LAG(month_total) OVER (PARTITION BY "customer_id"
                                      ORDER BY month_start)      AS diff
    FROM monthly_totals
)
SELECT
    "customer_id"                                AS CUSTOMER_ID,
    TO_CHAR(month_start, 'YYYY-MM')              AS MONTH,
    ROUND(ABS(diff), 2)                          AS MAX_MONTHLY_DIFF
FROM month_over_month
WHERE diff IS NOT NULL
ORDER BY ABS(diff) DESC NULLS LAST
LIMIT 1;