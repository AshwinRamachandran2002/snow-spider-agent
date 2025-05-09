/* -------------------------------------------------------------
   Monthly closing balances, monthly change and running total
   for every customer – months with no activity are retained
   ------------------------------------------------------------- */
WITH txn AS (   -- sign every transaction
    SELECT
        "customer_id",
        TO_DATE("txn_date",'YYYY-MM-DD')                    AS txn_dt,
        CASE 
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
            ELSE 0
        END                                                AS amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
/* first and last month containing any transaction for each customer */
customer_month_bounds AS (
    SELECT
        "customer_id",
        DATE_TRUNC('MONTH', MIN(txn_dt))                    AS first_month,
        DATE_TRUNC('MONTH', MAX(txn_dt))                    AS last_month,
        DATEDIFF('MONTH',
                 DATE_TRUNC('MONTH', MIN(txn_dt)),
                 DATE_TRUNC('MONTH', MAX(txn_dt))) + 1      AS month_span      -- # months to generate
    FROM txn
    GROUP BY "customer_id"
),
/* a sequence of numbers (0,1,2,...) large enough for the longest span */
numbers AS (
    SELECT seq4() AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 1200))                 -- 100 years of months
),
/* generate one row per customer-month within the span */
calendar_months AS (
    SELECT
        cmb."customer_id",
        DATEADD('MONTH', num.n, cmb.first_month)            AS month_start
    FROM customer_month_bounds cmb
    JOIN numbers num
      ON num.n < cmb.month_span
),
/* net movement (deposit – withdrawal) per customer-month */
monthly_changes AS (
    SELECT
        "customer_id",
        DATE_TRUNC('MONTH', txn_dt)                         AS month_start,
        SUM(amount)                                         AS monthly_change
    FROM txn
    GROUP BY "customer_id", DATE_TRUNC('MONTH', txn_dt)
),
/* attach zero change to months with no activity */
filled_months AS (
    SELECT
        cm."customer_id",
        cm.month_start,
        COALESCE(mc.monthly_change, 0)                      AS monthly_change
    FROM calendar_months cm
    LEFT JOIN monthly_changes mc
           ON mc."customer_id" = cm."customer_id"
          AND mc.month_start   = cm.month_start
),
/* running balance = closing balance at end of the month */
running_balance AS (
    SELECT
        "customer_id",
        month_start,
        monthly_change,
        SUM(monthly_change)
          OVER (PARTITION BY "customer_id"
                ORDER BY month_start
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
    FROM filled_months
)
SELECT
    "customer_id",
    TO_CHAR(month_start,'YYYY-MM')          AS "month_year",
    monthly_change                          AS "monthly_change",
    closing_balance                         AS "closing_balance"
FROM running_balance
ORDER BY "customer_id", month_start NULLS LAST;