WITH monthly_net AS (
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date) AS txn_month,
        SUM(
            CASE
                WHEN txn_type = 'deposit' THEN txn_amount      -- positive inflow
                ELSE                       -txn_amount         -- negative outflow
            END
        ) AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, txn_month
),
running_bal AS (   -- running balance per customer at each month‑end
    SELECT
        customer_id,
        txn_month,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY      txn_month
        ) AS balance_to_date
    FROM monthly_net
),
total_bal AS (     -- total balance across all customers at each month‑end
    SELECT
        txn_month,
        SUM(balance_to_date) AS total_balance
    FROM running_bal
    GROUP BY txn_month
),
prev_total AS (    -- attach the previous month’s total balance
    SELECT
        DATE(txn_month || '-01') AS month_start,
        LAG(total_balance) OVER (ORDER BY txn_month) AS prev_month_total_balance
    FROM total_bal
)
SELECT
    month_start,
    CASE
        WHEN prev_month_total_balance < 0 THEN 0           -- replace negatives with 0
        ELSE prev_month_total_balance
    END AS prev_month_total_balance
FROM prev_total
WHERE prev_month_total_balance IS NOT NULL                -- drop the first month
ORDER BY month_start;