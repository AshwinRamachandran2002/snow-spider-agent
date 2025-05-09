WITH cust_limits AS (          -- earliest and latest txn dates per customer
    SELECT 
        customer_id,
        MIN(DATE(txn_date)) AS start_date,
        MAX(DATE(txn_date)) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),
/* build a complete day‑by‑day calendar for every customer */
calendar(customer_id, cal_date) AS (
    SELECT customer_id, start_date
    FROM cust_limits
    UNION ALL
    SELECT 
        customer_id,
        DATE(cal_date,'+1 day')
    FROM calendar
    JOIN cust_limits USING (customer_id)
    WHERE cal_date < end_date
),
/* net change for each transaction day: deposits +, everything else –  */
daily_change AS (
    SELECT
        customer_id,
        DATE(txn_date)                           AS txn_date,
        SUM(CASE WHEN txn_type = 'deposit' 
                 THEN  txn_amount 
                 ELSE -txn_amount END)          AS net_change
    FROM customer_transactions
    GROUP BY customer_id, DATE(txn_date)
),
/* attach each calendar day to its net change (0 if none) and rank days */
per_day AS (
    SELECT
        c.customer_id,
        c.cal_date,
        COALESCE(d.net_change,0) AS net_change,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id 
            ORDER BY c.cal_date
        ) AS rn
    FROM calendar c
    LEFT JOIN daily_change d
           ON c.customer_id = d.customer_id
          AND c.cal_date    = d.txn_date
),
/* recursive running‑balance with “no negative balance” rule */
rec_balance(customer_id, rn, balance) AS (
    SELECT 
        customer_id,
        rn,
        MAX(0.0, net_change)                  -- day 1 balance
    FROM per_day
    WHERE rn = 1
    UNION ALL
    SELECT 
        p.customer_id,
        p.rn,
        MAX(0.0,  r.balance + p.net_change)  -- carry forward, floor at 0
    FROM per_day      p
    JOIN rec_balance  r
      ON p.customer_id = r.customer_id
     AND p.rn         = r.rn + 1
),
/* daily balances with their actual calendar dates */
daily_balance AS (
    SELECT 
        p.customer_id,
        p.cal_date,
        r.balance
    FROM per_day      p
    JOIN rec_balance  r
      ON p.customer_id = r.customer_id
     AND p.rn         = r.rn
),
/* highest balance each customer reaches in every month */
customer_monthly_max AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', cal_date) AS month,
        MAX(balance)                AS max_daily_balance
    FROM daily_balance
    GROUP BY customer_id, month
)
SELECT
    month,
    ROUND(SUM(max_daily_balance),4) AS total_max_daily_balance
FROM customer_monthly_max
GROUP BY month
ORDER BY month;