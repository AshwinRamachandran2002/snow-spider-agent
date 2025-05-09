/* ------------------------------------------------------------
   Monthly closing balance (end-of-month) per customer
   – includes months with no account activity
   – shows net monthly change and running (cumulative) balance
-------------------------------------------------------------*/

WITH txn AS (      /* 1. normalise transactions  */
    SELECT
        "customer_id"                              AS customer_id,   -- give an un-quoted alias
        TO_DATE("txn_date")                        AS txn_dt,
        /* deposits are positive, withdrawals negative */
        CASE
            WHEN LOWER("txn_type") IN ('deposit','credit')    THEN  "txn_amount"
            WHEN LOWER("txn_type") IN ('withdrawal','withdraw','debit')
                                                           THEN - "txn_amount"
            ELSE 0
        END                                         AS amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

cust_range AS (   /* 2. first and last month seen per customer */
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(txn_dt))            AS min_mth,
        DATE_TRUNC('month', MAX(txn_dt))            AS max_mth
    FROM txn
    GROUP BY customer_id
),

month_series AS ( /* 3. generate every month for every customer */
    SELECT
        cr.customer_id,
        DATEADD(month, seq4(), cr.min_mth)          AS month_start
    FROM cust_range cr,
         TABLE(GENERATOR(ROWCOUNT => 1200)) g       -- 100-year safety net
    WHERE DATEADD(month, seq4(), cr.min_mth) <= cr.max_mth
),

monthly_change AS ( /* 4. net movement each month */
    SELECT
        customer_id,
        DATE_TRUNC('month', txn_dt)                 AS month_start,
        SUM(amt)                                    AS net_change
    FROM txn
    GROUP BY customer_id, DATE_TRUNC('month', txn_dt)
)

/* 5. final report */
SELECT
    ms.customer_id,
    LAST_DAY(ms.month_start, 'month')               AS month_end_date,
    COALESCE(mc.net_change, 0)                      AS monthly_change,
    SUM(COALESCE(mc.net_change, 0))
        OVER (PARTITION BY ms.customer_id
              ORDER BY ms.month_start)              AS closing_balance
FROM month_series  ms
LEFT JOIN monthly_change mc
       ON  mc.customer_id = ms.customer_id
       AND mc.month_start = ms.month_start
ORDER BY
    ms.customer_id,
    ms.month_start
;