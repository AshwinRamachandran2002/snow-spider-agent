WITH top_customers AS (
    /* 1. Ten customers who have paid the most in total */
    SELECT "customer_id"                               AS CUSTOMER_ID,
           SUM("amount")                               AS TOTAL_PAID
    FROM   "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP  BY "customer_id"
    ORDER  BY TOTAL_PAID DESC NULLS LAST
    LIMIT  10
),
monthly_totals AS (
    /* 2. Total paid by those customers each calendar month */
    SELECT  p."customer_id"                            AS CUSTOMER_ID,
            DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date")) AS MONTH_START,
            SUM(p."amount")                            AS MONTH_AMOUNT
    FROM    "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
    JOIN    top_customers tc
           ON p."customer_id" = tc.CUSTOMER_ID
    GROUP   BY p."customer_id",
             DATE_TRUNC('month', TO_TIMESTAMP(p."payment_date"))
),
monthly_diffs AS (
    /* 3. Month-over-month absolute change in payments */
    SELECT  CUSTOMER_ID,
            MONTH_START,
            ROUND(
                ABS(
                    MONTH_AMOUNT
                    - LAG(MONTH_AMOUNT) OVER (PARTITION BY CUSTOMER_ID
                                              ORDER BY MONTH_START)
                ), 2
            )                                          AS DIFF
    FROM    monthly_totals
)
SELECT  CUSTOMER_ID,
        TO_CHAR(MONTH_START, 'YYYY-MM')                AS MONTH_OF_CHANGE,
        DIFF                                           AS MAX_MONTHLY_DIFFERENCE
FROM    monthly_diffs
WHERE   DIFF IS NOT NULL
ORDER   BY DIFF DESC NULLS LAST
LIMIT   1;