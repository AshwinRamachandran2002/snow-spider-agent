WITH 
-- 1. Identify the 10 customers who have paid the most in total
"top_customers" AS (
    SELECT "customer_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC NULLS LAST
    LIMIT 10
),

-- 2. Calculate each of those customers’ total payment amount per month
"monthly_totals" AS (
    SELECT
        p."customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date"))          AS "month_start",
        SUM(p."amount")                                              AS "monthly_amount"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    JOIN "top_customers" tc
          ON p."customer_id" = tc."customer_id"
    GROUP BY
        p."customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date"))
),

-- 3. Compute the absolute month-over-month change for each customer
"diffs" AS (
    SELECT
        "customer_id",
        "month_start",
        ABS("monthly_amount" 
            - LAG("monthly_amount") OVER (PARTITION BY "customer_id"
                                           ORDER BY "month_start"))  AS "diff"
    FROM "monthly_totals"
)

-- 4. Pick the single largest change and present the result
SELECT
    "customer_id",
    TO_CHAR("month_start", 'YYYY-MM')      AS "month",
    ROUND("diff", 2)                       AS "month_over_month_change"
FROM "diffs"
WHERE "diff" IS NOT NULL
ORDER BY "diff" DESC NULLS LAST
LIMIT 1;