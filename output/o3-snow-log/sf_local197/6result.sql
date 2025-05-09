WITH "TOP_CUSTOMERS" AS (         -- 1) 10 customers who have paid the most in total
    SELECT "customer_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC NULLS LAST
    LIMIT 10
),
"MONTHLY_TOTALS" AS (             -- 2) monthly payment totals for those customers
    SELECT
        "customer_id",
        DATE_TRUNC('month', CAST("payment_date" AS TIMESTAMP_NTZ)) AS "month_start",
        SUM("amount") AS "total_amount"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    WHERE "customer_id" IN (SELECT "customer_id" FROM "TOP_CUSTOMERS")
    GROUP BY "customer_id", "month_start"
),
"DIFFS" AS (                      -- 3) month-over-month absolute differences
    SELECT
        "customer_id",
        "month_start",
        ABS("total_amount"
            - LAG("total_amount") OVER (PARTITION BY "customer_id"
                                         ORDER BY "month_start")) AS "diff"
    FROM "MONTHLY_TOTALS"
)
-- 4) pick the largest month-over-month change
SELECT
    "customer_id",
    TO_CHAR("month_start", 'YYYY-MM') AS "month",
    ROUND("diff", 2)               AS "difference"
FROM "DIFFS"
WHERE "diff" IS NOT NULL
ORDER BY "diff" DESC NULLS LAST
LIMIT 1;