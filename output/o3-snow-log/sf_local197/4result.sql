WITH "TOP10_CUSTOMERS" AS (
    SELECT 
        "customer_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC NULLS LAST
    LIMIT 10
),
"MONTHLY_TOTALS" AS (
    SELECT
        p."customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date"))       AS "month_start",
        SUM(p."amount")                                           AS "month_total"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    WHERE p."customer_id" IN (SELECT "customer_id" FROM "TOP10_CUSTOMERS")
    GROUP BY p."customer_id", DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date"))
),
"MONTHLY_DIFFS" AS (
    SELECT
        m."customer_id",
        m."month_start",
        m."month_total",
        LAG(m."month_total") OVER (PARTITION BY m."customer_id" 
                                   ORDER BY m."month_start")      AS "prev_month_total"
    FROM "MONTHLY_TOTALS" m
),
"CHANGES" AS (
    SELECT
        "customer_id",
        "month_start",
        ("month_total" - "prev_month_total")                      AS "diff",
        ABS("month_total" - "prev_month_total")                   AS "abs_diff"
    FROM "MONTHLY_DIFFS"
    WHERE "prev_month_total" IS NOT NULL
)
SELECT
    "customer_id",
    TO_CHAR("month_start", 'YYYY-MM')                             AS "month",
    ROUND("abs_diff", 2)                                          AS "difference"
FROM "CHANGES"
ORDER BY "abs_diff" DESC NULLS LAST
LIMIT 1;