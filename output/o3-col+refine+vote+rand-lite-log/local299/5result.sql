WITH daily_delta AS (                     -- net movement per customer-day
    SELECT
        customer_id,
        txn_date,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN  txn_amount
                 ELSE -txn_amount END)    AS delta
    FROM   customer_transactions
    GROUP  BY customer_id, txn_date
),
running_bal AS (                          -- cumulative running balance
    SELECT
        customer_id,
        txn_date,
        SUM(delta) OVER (PARTITION BY customer_id
                         ORDER BY txn_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance
    FROM   daily_delta
),
with_first AS (                           -- attach each customer's first txn_date
    SELECT
        rb.*,
        MIN(txn_date) OVER (PARTITION BY customer_id) AS first_txn_date
    FROM   running_bal rb
),
avg_30d AS (                              -- 30-day rolling average (floored at 0)
    SELECT
        customer_id,
        txn_date,
        MAX(0,
            AVG(balance) OVER (PARTITION BY customer_id
                               ORDER BY txn_date
                               ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)) AS avg_30d_bal,
        first_txn_date
    FROM   with_first
    WHERE  julianday(txn_date) - julianday(first_txn_date) >= 29        -- need full 30 days
),
monthly_max AS (                          -- max 30-day avg per customer-month
    SELECT
        customer_id,
        SUBSTR(txn_date,1,7)                       AS year_month,       -- YYYY-MM
        MAX(avg_30d_bal)                           AS max_30d_avg_bal
    FROM   avg_30d
    WHERE  SUBSTR(txn_date,1,7) > SUBSTR(first_txn_date,1,7)            -- skip baseline month
    GROUP  BY customer_id, year_month
)
SELECT
    year_month,
    ROUND(SUM(max_30d_avg_bal), 4) AS monthly_total_max_30d_avg_balance
FROM   monthly_max
GROUP  BY year_month
ORDER  BY year_month;