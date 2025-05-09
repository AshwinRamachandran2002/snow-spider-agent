WITH RECURSIVE
/* 1. Earliest and latest transaction date for each customer */
cust_dates AS (
    SELECT  customer_id,
            DATE(MIN(txn_date)) AS min_date,
            DATE(MAX(txn_date)) AS max_date
    FROM    customer_transactions
    GROUP BY customer_id
),

/* 2. Day‑by‑day calendar for every customer */
date_series AS (
    SELECT  customer_id,
            min_date AS txn_date
    FROM    cust_dates
    UNION ALL
    SELECT  ds.customer_id,
            DATE(ds.txn_date,'+1 day')          -- next day
    FROM    date_series ds
    JOIN    cust_dates cd
           ON cd.customer_id = ds.customer_id
    WHERE   DATE(ds.txn_date,'+1 day') <= cd.max_date
),

/* 3. Net movement per customer per day */
daily_net AS (
    SELECT  customer_id,
            DATE(txn_date) AS txn_date,
            SUM(
                CASE
                    WHEN LOWER(txn_type) = 'deposit'    THEN  txn_amount
                    WHEN LOWER(txn_type) = 'withdrawal' THEN -txn_amount
                    ELSE 0
                END
            ) AS net_amount
    FROM    customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),

/* 4. Running (cumulative) balance – negatives forced to zero */
daily_bal AS (
    SELECT  customer_id,
            txn_date,
            CASE WHEN running_bal < 0 THEN 0 ELSE running_bal END AS balance
    FROM (
        SELECT  ds.customer_id,
                ds.txn_date,
                SUM( COALESCE(dn.net_amount,0) )
                OVER (PARTITION BY ds.customer_id
                      ORDER BY ds.txn_date
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_bal
        FROM    date_series ds
        LEFT JOIN daily_net dn
               ON dn.customer_id = ds.customer_id
              AND dn.txn_date    = ds.txn_date
    )
),

/* 5. Highest daily balance each month for every customer */
monthly_max AS (
    SELECT  customer_id,
            STRFTIME('%Y-%m', txn_date) AS month,
            MAX(balance) AS max_balance
    FROM    daily_bal
    GROUP BY customer_id, STRFTIME('%Y-%m', txn_date)
)

/* 6. Monthly total of those maxima across all customers */
SELECT  month,
        SUM(max_balance) AS monthly_total_max_balance
FROM    monthly_max
GROUP BY month
ORDER BY month;