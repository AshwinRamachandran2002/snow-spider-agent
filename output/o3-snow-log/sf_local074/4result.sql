/* --------------------------------------------------------------------
   Monthly movement (+/-) and closing balance for every customer.
   Months with no activity are still present with 0 change.
---------------------------------------------------------------------*/
WITH RECURSIVE
/* 1.  Movements per customer & month --------------------------------*/
MONTHLY_MOVEMENTS AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date"))            AS month_start,
        SUM(
            CASE 
                 WHEN LOWER("txn_type") = 'deposit'    THEN  "txn_amount"
                 WHEN LOWER("txn_type") = 'withdrawal' THEN - "txn_amount"
                 ELSE 0
            END
        )                                                   AS monthly_change
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", month_start
),

/* 2.  First and last months with any activity -----------------------*/
CUSTOMER_RANGE AS (
    SELECT
        "customer_id",
        MIN(DATE_TRUNC('month', TO_DATE("txn_date"))) AS first_month,
        MAX(DATE_TRUNC('month', TO_DATE("txn_date"))) AS last_month
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id"
),

/* 3.  Recursively generate every month between first & last --------*/
MONTH_RECURSIVE AS (
    -- anchor row
    SELECT
        "customer_id",
        first_month                          AS month_start,
        last_month
    FROM CUSTOMER_RANGE
    
    UNION ALL
    
    -- recursive part
    SELECT
        "customer_id",
        DATEADD(month, 1, month_start)       AS month_start,
        last_month
    FROM MONTH_RECURSIVE
    WHERE DATEADD(month, 1, month_start) <= last_month
),

ALL_MONTHS AS (
    SELECT
        "customer_id",
        month_start
    FROM MONTH_RECURSIVE
)

/* 4.  Combine all months with movements and compute balances --------*/
SELECT
       am."customer_id",
       LAST_DAY(am.month_start)                           AS month_end_date,
       COALESCE(mm.monthly_change, 0)                     AS monthly_change,
       SUM(COALESCE(mm.monthly_change, 0))
           OVER (PARTITION BY am."customer_id"
                 ORDER BY am.month_start)                 AS closing_balance
FROM ALL_MONTHS                     am
LEFT JOIN MONTHLY_MOVEMENTS         mm
       ON  am."customer_id" = mm."customer_id"
       AND am.month_start   = mm.month_start
ORDER BY am."customer_id", month_end_date NULLS LAST;