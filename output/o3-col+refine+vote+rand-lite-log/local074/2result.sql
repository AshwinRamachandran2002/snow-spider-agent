/*  Closing balance summary – every month for every customer  */

WITH RECURSIVE
-- 1) Find the overall date span of all transactions
date_bounds AS (
    SELECT date(MIN("txn_date"),'start of month') AS min_m,
           date(MAX("txn_date"),'start of month') AS max_m
    FROM   "customer_transactions"
),

-- 2) Generate every month that falls within that span
months AS (
    SELECT min_m AS month_start
    FROM   date_bounds
    UNION ALL
    SELECT date(month_start,'+1 month')
    FROM   months, date_bounds
    WHERE  month_start < (SELECT max_m FROM date_bounds)
),

-- 3) List of all customers that have ever had a transaction
customers AS (
    SELECT DISTINCT "customer_id"
    FROM   "customer_transactions"
),

-- 4) Cross-join customers to every month so that “no-activity” months appear
customer_months AS (
    SELECT c."customer_id",
           m.month_start
    FROM   customers c
    CROSS  JOIN months  m
),

-- 5) Calculate the signed monthly change for months that DO have activity
monthly_change AS (
    SELECT "customer_id",
           date("txn_date",'start of month')          AS month_start,
           SUM(CASE WHEN "txn_type"='deposit'    THEN  "txn_amount"
                    WHEN "txn_type"='withdrawal' THEN - "txn_amount"
               END)                                  AS change_amt
    FROM   "customer_transactions"
    GROUP  BY "customer_id", date("txn_date",'start of month')
),

-- 6) Merge the “all months” list with the actual changes (fill gaps with 0)
joined AS (
    SELECT cm."customer_id",
           cm.month_start,
           COALESCE(mc.change_amt,0) AS monthly_change
    FROM   customer_months cm
    LEFT   JOIN monthly_change mc
           ON  cm."customer_id" = mc."customer_id"
           AND cm.month_start   = mc.month_start
)

-- 7) Produce the requested output: end-of-month date, change, and running balance
SELECT "customer_id",
       date(month_start,'start of month','+1 month','-1 day')   AS month_end,  -- last day of month
       monthly_change,
       SUM(monthly_change) OVER (PARTITION BY "customer_id"
                                 ORDER BY month_start)          AS closing_balance
FROM   joined
ORDER  BY "customer_id", month_end;