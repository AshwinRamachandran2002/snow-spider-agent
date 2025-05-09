WITH daily_txn AS (                       -- net movement per customer and day
    SELECT
        customer_id,
        DATE(txn_date)                            AS txn_date,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN  txn_amount
                 ELSE -txn_amount END)            AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),
cust_bounds AS (                               -- first and last date per customer
    SELECT
        customer_id,
        MIN(DATE(txn_date)) AS min_date,
        MAX(DATE(txn_date)) AS max_date
    FROM customer_transactions
    GROUP BY customer_id
),
-- create a calendar‑day row for every customer between min and max dates
all_dates(customer_id, txn_date) AS (
    SELECT customer_id, min_date
    FROM   cust_bounds
    UNION ALL
    SELECT ad.customer_id,
           DATE(ad.txn_date,'+1 day')
    FROM   all_dates  ad
    JOIN   cust_bounds cb
           ON  cb.customer_id = ad.customer_id
           AND DATE(ad.txn_date,'+1 day') <= cb.max_date
),
daily_bal AS (                               -- fill missing days with zero movement
    SELECT
        ad.customer_id,
        ad.txn_date,
        COALESCE(dt.net_amount,0) AS net_amount
    FROM   all_dates ad
    LEFT JOIN daily_txn dt
           ON  dt.customer_id = ad.customer_id
           AND dt.txn_date     = ad.txn_date
),
running_bal AS (                             -- running end‑of‑day balance
    SELECT
        customer_id,
        txn_date,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM daily_bal
),
rolling_30d AS (                             -- 30‑day rolling average (>=30 days)
    SELECT
        customer_id,
        txn_date,
        CASE
            WHEN cnt_30 >= 30
            THEN CASE WHEN avg_30 < 0 THEN 0 ELSE avg_30 END
            ELSE NULL
        END AS avg_30d_balance
    FROM (
        SELECT
            customer_id,
            txn_date,
            COUNT(*) OVER (
                PARTITION BY customer_id
                ORDER BY txn_date
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )                                   AS cnt_30,
            AVG(running_balance) OVER (
                PARTITION BY customer_id
                ORDER BY txn_date
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            )                                   AS avg_30
        FROM running_bal
    )
),
month_max AS (                              -- max 30‑day avg per customer & month
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)           AS month,
        MAX(avg_30d_balance)                  AS max_30d_avg_balance
    FROM rolling_30d
    WHERE avg_30d_balance IS NOT NULL
    GROUP BY customer_id, month
),
baseline_month AS (                         -- each customer’s first activity month
    SELECT
        customer_id,
        strftime('%Y-%m', MIN(DATE(txn_date))) AS first_month
    FROM customer_transactions
    GROUP BY customer_id
),
filtered AS (                               -- exclude the baseline month
    SELECT m.month,
           m.max_30d_avg_balance
    FROM   month_max       m
    JOIN   baseline_month  b
           ON m.customer_id = b.customer_id
    WHERE  m.month <> b.first_month
)
SELECT
    month,
    ROUND(SUM(max_30d_avg_balance),4) AS total_max_30d_avg_balance
FROM   filtered
GROUP  BY month
ORDER  BY month;