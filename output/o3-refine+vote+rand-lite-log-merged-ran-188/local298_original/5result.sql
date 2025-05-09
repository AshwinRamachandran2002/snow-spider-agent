WITH trx AS (
    /* 1.  Sign each transaction: deposits (+), everything else (–) */
    SELECT
        customer_id,
        DATE(txn_date)                                                      AS txn_date,
        CASE
            WHEN LOWER(txn_type) = 'deposit' THEN  txn_amount     /* credit */
            ELSE                           -1 * txn_amount        /* debit  */
        END                                                               AS amount
    FROM customer_transactions
),

/* 2.  Net movement for every customer‑month */
cust_month_change AS (
    SELECT
        customer_id,
        DATE(STRFTIME('%Y-%m-01', txn_date))  AS month_start,
        SUM(amount)                           AS month_change
    FROM trx
    GROUP BY customer_id, month_start
),

/* 3.  Helper lists of all months and all customers (to back‑fill zeros) */
months AS (
    SELECT DISTINCT DATE(STRFTIME('%Y-%m-01', txn_date)) AS month_start
    FROM customer_transactions
),
customers AS (
    SELECT DISTINCT customer_id FROM customer_transactions
),

/* 4.  Make sure every customer has a row for every month (missing → 0) */
cust_month_filled AS (
    SELECT
        c.customer_id,
        m.month_start,
        COALESCE(cm.month_change, 0) AS month_change
    FROM customers  c
    CROSS JOIN months m
    LEFT  JOIN cust_month_change cm
           ON cm.customer_id = c.customer_id
          AND cm.month_start  = m.month_start
),

/* 5.  Cumulative balance for each customer at the END of every month */
cust_cum AS (
    SELECT
        customer_id,
        month_start,
        SUM(month_change) OVER (PARTITION BY customer_id
                                ORDER BY month_start) AS balance_end_of_month
    FROM cust_month_filled
),

/* 6.  Total balance across all customers for each month
        – replace negative individual balances with 0 before summing */
totals AS (
    SELECT
        month_start,
        SUM(CASE
                WHEN balance_end_of_month < 0 THEN 0
                ELSE balance_end_of_month
            END) AS total_balance
    FROM cust_cum
    GROUP BY month_start
),

/* 7.  Shift the balance forward one month so each row shows the
        PREVIOUS month’s total balance */
shifted AS (
    SELECT
        DATE(STRFTIME('%Y-%m-01', month_start, '+1 month')) AS month,
        total_balance                                       AS previous_month_total_balance
    FROM totals
)

/* 8.  Final output – exclude the very first month (which has no “previous”) */
SELECT
    month,
    previous_month_total_balance
FROM shifted
WHERE month > (SELECT MIN(month) FROM shifted)   -- drop baseline month
ORDER BY month;