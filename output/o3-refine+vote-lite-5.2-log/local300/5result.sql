WITH
/* 1.  Net value of each customer’s transactions per calendar day */
daily_net AS (
    SELECT
        customer_id,
        date(txn_date) AS txn_date,
        SUM(
            CASE
                WHEN lower(txn_type) = 'deposit'    THEN  txn_amount          -- money in
                WHEN lower(txn_type) = 'withdrawal' THEN -txn_amount          -- money out
                ELSE 0                                                     -- ignore all else
            END
        ) AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, date(txn_date)
),
/* 2.  Earliest and latest transaction dates for every customer */
customer_range AS (
    SELECT
        customer_id,
        MIN(date(txn_date)) AS start_date,
        MAX(date(txn_date)) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),
/* 3.  Calendar‑date rows for every customer (recursive date series) */
all_dates(customer_id, txn_date, end_date) AS (
    SELECT customer_id, start_date, end_date
    FROM   customer_range
    UNION ALL
    SELECT customer_id,
           date(txn_date,'+1 day'),
           end_date
    FROM   all_dates
    WHERE  txn_date < end_date
),
/* 4.  Running balance for each day */
running AS (
    SELECT
        d.customer_id,
        d.txn_date,
        SUM(COALESCE(n.net_amount,0)) OVER (
              PARTITION BY d.customer_id
              ORDER BY d.txn_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS balance_raw
    FROM   all_dates d
    LEFT  JOIN daily_net n
           ON n.customer_id = d.customer_id
          AND n.txn_date    = d.txn_date
),
/* 5.  Final daily balance (no negatives) */
daily_balances AS (
    SELECT
        customer_id,
        txn_date,
        CASE WHEN balance_raw < 0 THEN 0 ELSE balance_raw END AS daily_balance
    FROM   running
),
/* 6.  Highest daily balance each month for every customer */
monthly_customer_max AS (
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date) AS month,
        MAX(daily_balance)          AS max_daily_balance
    FROM   daily_balances
    GROUP BY customer_id, month
)
/* 7.  Monthly total of those customer‑level peaks */
SELECT
    month,
    SUM(max_daily_balance) AS monthly_total_max_balance
FROM   monthly_customer_max
GROUP BY month
ORDER BY month;