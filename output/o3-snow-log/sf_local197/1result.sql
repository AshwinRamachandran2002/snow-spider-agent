/* 1. Identify the ten customers who have paid the most in total. 
   2. For those customers, aggregate their payments by month.
   3. Compute the month-over-month difference per customer.
   4. Find the single largest (absolute) difference and report the customer,
      the (later) month in which it occurred, and the difference rounded to 2 dp. */

WITH top_customers AS (   -- step 1
    SELECT "customer_id"
    FROM   SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP  BY "customer_id"
    ORDER  BY SUM("amount") DESC NULLS LAST
    LIMIT  10
),
monthly_totals AS (       -- step 2
    SELECT
        p."customer_id",
        DATE_TRUNC('MONTH', TO_TIMESTAMP(p."payment_date")) AS month_start,
        SUM(p."amount")                                   AS month_amt
    FROM   SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
           JOIN top_customers tc
             ON p."customer_id" = tc."customer_id"
    GROUP  BY p."customer_id", DATE_TRUNC('MONTH', TO_TIMESTAMP(p."payment_date"))
),
month_diffs AS (          -- step 3
    SELECT
        "customer_id",
        month_start,
        ABS(month_amt 
            - LAG(month_amt) OVER (PARTITION BY "customer_id" ORDER BY month_start)
           ) AS diff_amt
    FROM   monthly_totals
)
SELECT                    -- step 4
       "customer_id",
       TO_CHAR(month_start, 'YYYY-MM')  AS "month",
       ROUND(diff_amt, 2)               AS "month_over_month_diff"
FROM   month_diffs
WHERE  diff_amt IS NOT NULL
ORDER  BY diff_amt DESC NULLS LAST
LIMIT  1;