WITH RECURSIVE
/* 1.  Daily net movement (deposits – withdrawals) */
daily_net AS (
    SELECT  customer_id,
            DATE(txn_date)                     AS txn_date,
            SUM(CASE
                    WHEN txn_type = 'deposit'    THEN  txn_amount
                    WHEN txn_type = 'withdrawal' THEN -txn_amount
                    ELSE 0
                END)                           AS net_change
    FROM    customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),

/* 2.  Earliest and latest dates for every customer */
date_span AS (
    SELECT  customer_id,
            DATE(MIN(txn_date)) AS start_date,
            DATE(MAX(txn_date)) AS end_date
    FROM    customer_transactions
    GROUP BY customer_id
),

/* 3.  Produce one row per customer-day between start and end dates */
calendar AS (
    SELECT  customer_id,
            start_date                       AS txn_date,
            end_date
    FROM    date_span
    UNION ALL
    SELECT  customer_id,
            DATE(txn_date,'+1 day')          AS txn_date,
            end_date
    FROM    calendar
    WHERE   DATE(txn_date,'+1 day') <= end_date
),

/* 4.  Recursively derive daily balances, clamping negatives to zero */
recursive_balances AS (
    /* base day (each customer’s start_date) */
    SELECT  c.customer_id,
            c.txn_date,
            CASE
                WHEN COALESCE(dn.net_change,0) < 0 THEN 0
                ELSE COALESCE(dn.net_change,0)
            END                               AS daily_balance,
            c.end_date
    FROM    calendar c
    JOIN    date_span ds
           ON ds.customer_id = c.customer_id
          AND ds.start_date = c.txn_date
    LEFT JOIN daily_net dn
           ON dn.customer_id = c.customer_id
          AND dn.txn_date    = c.txn_date

    UNION ALL

    /* every following day */
    SELECT  c.customer_id,
            c.txn_date,
            CASE
                WHEN (rb.daily_balance + COALESCE(dn.net_change,0)) < 0
                     THEN 0
                ELSE  (rb.daily_balance + COALESCE(dn.net_change,0))
            END                               AS daily_balance,
            rb.end_date
    FROM    recursive_balances rb
    JOIN    calendar         c
           ON rb.customer_id = c.customer_id
          AND DATE(rb.txn_date,'+1 day') = c.txn_date
    LEFT JOIN daily_net      dn
           ON dn.customer_id = c.customer_id
          AND dn.txn_date    = c.txn_date
    WHERE   c.txn_date <= rb.end_date
),

/* 5.  Per-customer, per-month highest balance */
monthly_customer_max AS (
    SELECT  customer_id,
            STRFTIME('%Y-%m', txn_date)   AS year_month,
            MAX(daily_balance)            AS max_daily_balance
    FROM    recursive_balances
    GROUP BY customer_id, year_month
)

/* 6.  Sum those maxima across customers for the final monthly totals */
SELECT  year_month,
        SUM(max_daily_balance) AS total_max_daily_balance
FROM    monthly_customer_max
GROUP BY year_month
ORDER BY year_month;