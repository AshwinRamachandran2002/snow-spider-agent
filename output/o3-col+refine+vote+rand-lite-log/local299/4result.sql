WITH daily_balances AS (          -- 1. running balance per customer & day
    SELECT
        customer_id,
        txn_date,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN txn_amount
                 ELSE -txn_amount
            END)
        OVER (PARTITION BY customer_id
              ORDER BY txn_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
    FROM customer_transactions
),

rolling_30d AS (                  -- 2. 30-day rolling average balance
    SELECT
        customer_id,
        txn_date,
        AVG(running_balance)
        OVER (PARTITION BY customer_id
              ORDER BY txn_date
              ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS avg_30d_bal
    FROM daily_balances
),

nonneg_avg AS (                   -- 3. zero-out any negative averages
    SELECT
        customer_id,
        txn_date,
        CASE WHEN avg_30d_bal < 0 THEN 0 ELSE avg_30d_bal END AS avg_30d_nonneg
    FROM rolling_30d
    WHERE avg_30d_bal IS NOT NULL        -- ensure a full 30-day window
),

monthly_max AS (                  -- 4. max 30-day avg per customer & month
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date) AS yyyy_mm,
        MAX(avg_30d_nonneg)         AS max_30d_avg_in_month
    FROM nonneg_avg
    GROUP BY customer_id, yyyy_mm
),

baseline_month AS (               -- 5. first (baseline) month for each customer
    SELECT
        customer_id,
        MIN(strftime('%Y-%m', txn_date)) AS baseline_mm
    FROM customer_transactions
    GROUP BY customer_id
),

exclude_baseline AS (             -- 6. discard each customer’s baseline month
    SELECT m.*
    FROM   monthly_max  AS m
    JOIN   baseline_month AS b
           ON m.customer_id = b.customer_id
    WHERE  m.yyyy_mm <> b.baseline_mm
)

-- 7. final monthly totals across all customers
SELECT
    yyyy_mm                               AS month,
    SUM(max_30d_avg_in_month)             AS sum_max_30d_avg
FROM   exclude_baseline
GROUP  BY yyyy_mm
ORDER  BY yyyy_mm;