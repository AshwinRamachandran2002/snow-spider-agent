WITH RECURSIVE
/*--------------------------------------------------*
 | 1. Sign every transaction (+ for deposits, – for withdrawals)
 *--------------------------------------------------*/
customer_txns AS (
    SELECT
        customer_id,
        DATE(txn_date)                                   AS txn_date,
        CASE
            WHEN LOWER(txn_type) = 'deposit'                     THEN  txn_amount
            WHEN LOWER(txn_type) IN ('withdraw','withdrawal')    THEN -txn_amount
            ELSE 0
        END                                             AS amount
    FROM customer_transactions
),

/*--------------------------------------------------*
 | 2. Define the first and last months in the data
 *--------------------------------------------------*/
bounds AS (
    SELECT
        DATE(SUBSTR(MIN(txn_date),1,7) || '-01') AS min_month_start,
        DATE(SUBSTR(MAX(txn_date),1,7) || '-01') AS max_month_start
    FROM customer_transactions
),

/*--------------------------------------------------*
 | 3. Build a month calendar covering the full range
 *--------------------------------------------------*/
months(month_start) AS (
    SELECT min_month_start FROM bounds
    UNION ALL
    SELECT DATE(month_start, '+1 month')
    FROM   months, bounds
    WHERE  month_start < max_month_start
),

/*--------------------------------------------------*
 | 4. Give every customer a row for every month
 *--------------------------------------------------*/
customer_months AS (
    SELECT
        c.customer_id,
        m.month_start
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) AS c
    CROSS JOIN months AS m
),

/*--------------------------------------------------*
 | 5. Net change for each customer‑month
 *--------------------------------------------------*/
monthly_changes AS (
    SELECT
        cm.customer_id,
        cm.month_start,
        COALESCE(SUM(ct.amount),0) AS monthly_change
    FROM customer_months AS cm
    LEFT JOIN customer_txns AS ct
           ON  ct.customer_id = cm.customer_id
           AND strftime('%Y-%m', ct.txn_date) = strftime('%Y-%m', cm.month_start)
    GROUP BY cm.customer_id, cm.month_start
),

/*--------------------------------------------------*
 | 6. Running (cumulative) balance
 *--------------------------------------------------*/
balances AS (
    SELECT
        customer_id,
        month_start,
        monthly_change,
        SUM(monthly_change) OVER (
            PARTITION BY customer_id
            ORDER BY       month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS closing_balance
    FROM monthly_changes
)

/*--------------------------------------------------*
 | 7. Final ordered result
 *--------------------------------------------------*/
SELECT
    customer_id,
    strftime('%Y-%m', month_start) AS month,
    monthly_change,
    closing_balance
FROM   balances
ORDER  BY customer_id, month_start;