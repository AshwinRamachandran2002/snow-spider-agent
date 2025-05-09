WITH cust_dates AS (                 -- find each customer’s first and last txn dates
    SELECT  "customer_id",
            DATE(MIN("txn_date")) AS min_date,
            DATE(MAX("txn_date")) AS max_date
    FROM    "customer_transactions"
    GROUP BY "customer_id"
),
-- build a daily calendar for every customer
recursive_dates AS (
    SELECT  customer_id,
            min_date AS txn_date,
            max_date
    FROM    cust_dates
    UNION ALL
    SELECT  customer_id,
            DATE(txn_date,'+1 day'),
            max_date
    FROM    recursive_dates
    WHERE   txn_date < max_date
),
all_dates AS (
    SELECT  customer_id, txn_date
    FROM    recursive_dates
),
-- net movement for days that actually have transactions
daily_transactions AS (
    SELECT  "customer_id",
            DATE("txn_date")                 AS txn_date,
            SUM(CASE WHEN LOWER("txn_type")='deposit'
                     THEN  "txn_amount"
                     ELSE -1*"txn_amount" END) AS net_amount
    FROM    "customer_transactions"
    GROUP BY "customer_id", DATE("txn_date")
),
-- daily running balance, carrying forward zero on no‑txn days
daily_balances AS (
    SELECT  d.customer_id,
            d.txn_date,
            COALESCE(t.net_amount,0)                                           AS net_amount,
            SUM(COALESCE(t.net_amount,0)) OVER (
                   PARTITION BY d.customer_id
                   ORDER BY     d.txn_date
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)           AS running_balance
    FROM    all_dates d
    LEFT JOIN daily_transactions t
           ON d.customer_id = t.customer_id
          AND d.txn_date    = t.txn_date
),
-- 30‑day rolling average of the running balance (need 30 rows; negatives -> 0)
rolling_30 AS (
    SELECT  customer_id,
            txn_date,
            CASE
                 WHEN cnt = 30
                 THEN CASE WHEN avg_val < 0 THEN 0 ELSE avg_val END
                 ELSE NULL
            END AS avg_30d_bal
    FROM (
        SELECT  *,
                AVG(running_balance) OVER (
                        PARTITION BY customer_id
                        ORDER BY     txn_date
                        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS avg_val,
                COUNT(*)          OVER (
                        PARTITION BY customer_id
                        ORDER BY     txn_date
                        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS cnt
        FROM    daily_balances
    )
),
-- best (highest) 30‑day average per month for every customer
month_max AS (
    SELECT  customer_id,
            strftime('%Y-%m', txn_date)              AS month,
            MAX(avg_30d_bal)                         AS max_30d_bal
    FROM    rolling_30
    WHERE   avg_30d_bal IS NOT NULL
    GROUP BY customer_id, month
),
-- identify each customer’s very first month of activity
first_month AS (
    SELECT  customer_id,
            strftime('%Y-%m', MIN(DATE(txn_date)))   AS first_month
    FROM    "customer_transactions"
    GROUP BY customer_id
)
-- sum the per‑customer monthly maxima, skipping every customer’s first month
SELECT  m.month,
        ROUND(SUM(m.max_30d_bal),4) AS total_max_30d_avg_balance
FROM    month_max    m
JOIN    first_month  f
      ON m.customer_id = f.customer_id
WHERE   m.month <> f.first_month
GROUP BY m.month
ORDER BY m.month;