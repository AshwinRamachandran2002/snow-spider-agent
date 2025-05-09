/*-----------------------------------------------------------
Monthly change and running (closing) balance for every
customer, including months with no activity
-----------------------------------------------------------*/
WITH RECURSIVE
/* 1. find date span of the whole transaction history */
date_range AS (
  SELECT
    DATE(MIN("txn_date")) AS min_date,
    DATE(MAX("txn_date")) AS max_date
  FROM "customer_transactions"
),

/* 2. build a month calendar covering the whole span */
months(month_start) AS (
  SELECT DATE(min_date,'start of month')             -- first month
  FROM   date_range
  UNION ALL
  SELECT DATE(month_start,'+1 month')                -- next months
  FROM   months, date_range
  WHERE  month_start < DATE(max_date,'start of month')
),

/* 3. list of every customer that ever appeared */
customers AS (
  SELECT DISTINCT "customer_id"
  FROM   "customer_transactions"
),

/* 4. sign the amounts (+ for deposits, – for withdrawals) */
txn_signed AS (
  SELECT
    "customer_id",
    DATE("txn_date",'start of month') AS month_start,
    CASE
      WHEN LOWER("txn_type") = 'deposit'    THEN +1
      WHEN LOWER("txn_type") = 'withdrawal' THEN -1
      ELSE 0
    END * "txn_amount"                      AS signed_amount
  FROM "customer_transactions"
),

/* 5. net change per customer per month (could be zero rows) */
monthly_change AS (
  SELECT
    "customer_id",
    month_start,
    SUM(signed_amount) AS monthly_change
  FROM   txn_signed
  GROUP  BY "customer_id", month_start
),

/* 6. make sure every customer has a row for every month */
customer_calendar AS (
  SELECT
    c."customer_id",
    m.month_start
  FROM   customers c
  CROSS  JOIN months   m          -- all customer–month combos
),

/* 7. merge monthly change onto full calendar (NULL → 0) */
calendar_with_change AS (
  SELECT
    cc."customer_id",
    cc.month_start,
    COALESCE(mc.monthly_change,0) AS monthly_change
  FROM   customer_calendar  cc
  LEFT   JOIN monthly_change mc
         ON mc."customer_id" = cc."customer_id"
        AND mc.month_start   = cc.month_start
),

/* 8. running balance (closing balance) */
final AS (
  SELECT
    "customer_id",
    DATE(month_start,'start of month','+1 month','-1 day') AS month_end,  -- last day of month
    monthly_change,
    SUM(monthly_change) OVER (
        PARTITION BY "customer_id"
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS closing_balance
  FROM calendar_with_change
)

/* 9. output */
SELECT
  "customer_id",
  month_end,
  monthly_change,
  closing_balance
FROM final
ORDER BY "customer_id", month_end;