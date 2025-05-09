/*-----------------------------------------------------------
Summary   : Closing balance per customer at the end of every
            month, including months with no activity.
Database  : BANK_SALES_TRADING
Schema    : BANK_SALES_TRADING
Tables    : CUSTOMER_TRANSACTIONS
-----------------------------------------------------------*/
WITH trans AS (   /* 1.  Sign every transaction (deposits +, withdrawals –) */
    SELECT
        "customer_id",
        TO_DATE("txn_date", 'YYYY-MM-DD')                        AS txn_date,
        CASE
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN -"txn_amount"
            ELSE 0
        END                                                     AS signed_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
monthly_change AS (   /* 2.  Net movement for each customer-month             */
    SELECT
        "customer_id",
        DATE_TRUNC('month', txn_date)   AS month_start,
        SUM(signed_amount)              AS monthly_change
    FROM trans
    GROUP BY "customer_id", DATE_TRUNC('month', txn_date)
),
customers AS (        /* 3.  List of all customers                            */
    SELECT DISTINCT "customer_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
date_bounds AS (      /* 4.  Overall earliest & latest month in data          */
    SELECT
        DATE_TRUNC('month', MIN(TO_DATE("txn_date", 'YYYY-MM-DD'))) AS min_month_start,
        DATE_TRUNC('month', MAX(TO_DATE("txn_date", 'YYYY-MM-DD'))) AS max_month_start
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
months_spine AS (     /* 5.  Continuous month spine (max 100 yrs = 1200 rows) */
    SELECT
        DATEADD('month', seq4(),
                (SELECT min_month_start FROM date_bounds)) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 1200))
    WHERE month_start <= (SELECT max_month_start FROM date_bounds)
),
customer_months AS (  /* 6.  Every customer crossed with every month          */
    SELECT
        c."customer_id",
        m.month_start
    FROM customers      c
    CROSS JOIN months_spine m
)

/* 7.  Combine, fill gaps with 0, and accumulate to get closing balance */
SELECT
    cm."customer_id",
    LAST_DAY(cm.month_start)                                             AS month_end_date,
    COALESCE(mc.monthly_change, 0)                                       AS monthly_change,
    SUM(COALESCE(mc.monthly_change, 0))
        OVER (PARTITION BY cm."customer_id"
              ORDER BY cm.month_start)                                   AS closing_balance
FROM customer_months      cm
LEFT JOIN monthly_change  mc
       ON  cm."customer_id" = mc."customer_id"
       AND cm.month_start   = mc.month_start
ORDER BY cm."customer_id", cm.month_start;