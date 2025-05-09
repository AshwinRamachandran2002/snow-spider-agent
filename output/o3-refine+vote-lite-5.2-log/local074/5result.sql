/* -----------------------------------------------------------
   Monthly closing balance, net monthly change and running 
   (cumulative) balance for every customer.  Months with no
   activity are still shown with a zero net change and the
   previous month’s balance carried forward.
------------------------------------------------------------*/
WITH customer_bounds AS (   -- first / last month per customer
     SELECT
         "customer_id",
         date(substr(MIN("txn_date"),1,7)||'-01') AS start_month,
         date(substr(MAX("txn_date"),1,7)||'-01') AS end_month
     FROM   "customer_transactions"
     GROUP  BY "customer_id"
),
/* -----------------------------------------------------------
   Recursively build a complete month‑by‑month calendar for 
   every customer between their first and last transaction.
------------------------------------------------------------*/
months AS (
     SELECT 
         cb."customer_id",
         cb.start_month AS month_start
     FROM   customer_bounds cb
     UNION ALL
     SELECT 
         m."customer_id",
         date(m.month_start,'+1 month')           -- next month
     FROM   months m
     JOIN   customer_bounds cb
       ON   cb."customer_id" = m."customer_id"
     WHERE  m.month_start < cb.end_month
),
/* -----------------------------------------------------------
   Net movement (deposit = +, withdrawal = –) for each customer
   in each month in which at least one transaction occurred.
------------------------------------------------------------*/
txn_monthly AS (
     SELECT
         "customer_id",
         date(substr("txn_date",1,7)||'-01')      AS month_start,
         SUM(CASE
                 WHEN LOWER("txn_type")='deposit'     THEN  "txn_amount"
                 WHEN LOWER("txn_type")='withdrawal'  THEN -"txn_amount"
                 ELSE 0
             END)                                 AS monthly_change
     FROM   "customer_transactions"
     GROUP  BY "customer_id", month_start
),
/* -----------------------------------------------------------
   Combine the full calendar with monthly movements, filling
   missing months with a zero change.
------------------------------------------------------------*/
calendar_with_movements AS (
     SELECT
         m."customer_id",
         m.month_start,
         COALESCE(t.monthly_change,0) AS monthly_change
     FROM   months m
     LEFT   JOIN txn_monthly t
       ON   t."customer_id" = m."customer_id"
      AND   t.month_start   = m.month_start
)
/* -----------------------------------------------------------
   Final output: end‑of‑month date, that month’s net change,
   and the cumulative (closing) balance after the month ends.
------------------------------------------------------------*/
SELECT
    "customer_id",
    date(month_start,'+1 month','-1 day')          AS month_end_date,
    monthly_change,
    SUM(monthly_change) OVER (
        PARTITION BY "customer_id"
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                              AS closing_balance
FROM   calendar_with_movements
ORDER BY "customer_id", month_start;