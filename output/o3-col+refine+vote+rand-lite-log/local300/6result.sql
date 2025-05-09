WITH RECURSIVE
-- 1. First and last transaction date for every customer
bounds AS (
    SELECT
        customer_id,
        MIN(DATE(txn_date)) AS min_d,
        MAX(DATE(txn_date)) AS max_d
    FROM customer_transactions
    GROUP BY customer_id
),

-- 2. Build a complete daily calendar between min → max date per customer
calendar(customer_id, cal_date, max_d) AS (
    SELECT customer_id, min_d, max_d
    FROM bounds
    UNION ALL
    SELECT customer_id,
           DATE(cal_date,'+1 day'),
           max_d
    FROM calendar
    WHERE cal_date < max_d
),

-- 3. Net movement per customer-day  (deposits +, everything else –)
daily_net AS (
    SELECT
        customer_id,
        DATE(txn_date) AS txn_date,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN txn_amount
                 ELSE -txn_amount END) AS net_amt
    FROM customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),

-- 4. Running (cumulative) balance, clamped to ≥ 0
running_bal AS (
    SELECT
        customer_id,
        txn_date,
        MAX(0,
            SUM(net_amt) OVER (
                PARTITION BY customer_id
                ORDER BY txn_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        ) AS balance
    FROM daily_net
),

-- 5. Attach running balance to every calendar day (will be NULL where no txn)
full_days AS (
    SELECT
        c.customer_id,
        c.cal_date,
        r.balance
    FROM calendar c
    LEFT JOIN running_bal r
           ON r.customer_id = c.customer_id
          AND r.txn_date    = c.cal_date
),

-- 6. Forward-fill NULL balances; if still NULL treat as 0
filled_bal AS (
    SELECT
        f.customer_id,
        f.cal_date,
        COALESCE(
            (SELECT rb.balance
             FROM full_days rb
             WHERE rb.customer_id = f.customer_id
               AND rb.cal_date   <= f.cal_date
               AND rb.balance    IS NOT NULL
             ORDER BY rb.cal_date DESC
             LIMIT 1),
            0
        ) AS daily_balance
    FROM full_days f
),

-- 7. Highest daily balance each customer achieved in every month
cust_month_peak AS (
    SELECT
        customer_id,
        strftime('%Y-%m', cal_date) AS month,
        MAX(daily_balance)          AS peak_balance
    FROM filled_bal
    GROUP BY customer_id, month
)

-- 8. Sum those peaks across all customers to get the monthly totals
SELECT
    month,
    SUM(peak_balance) AS monthly_total_highest_balance
FROM cust_month_peak
GROUP BY month
ORDER BY month;