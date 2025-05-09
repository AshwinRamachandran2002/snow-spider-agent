WITH RECURSIVE
    -- 1. running balance per transaction, negative values floored at 0
    running AS (
        SELECT
            customer_id,
            DATE(txn_date) AS txn_date,
            CASE
                WHEN SUM(
                        CASE
                            WHEN txn_type = 'deposit' THEN txn_amount
                            ELSE -txn_amount
                        END
                     ) OVER (
                         PARTITION BY customer_id
                         ORDER BY DATE(txn_date)
                     ) < 0
                THEN 0
                ELSE SUM(
                        CASE
                            WHEN txn_type = 'deposit' THEN txn_amount
                            ELSE -txn_amount
                        END
                     ) OVER (
                         PARTITION BY customer_id
                         ORDER BY DATE(txn_date)
                     )
            END AS daily_balance
        FROM customer_transactions
    ),

    -- 2. first and last month for every customer
    cust_span AS (
        SELECT
            customer_id,
            DATE(MIN(txn_date), 'start of month') AS first_month,
            DATE(MAX(txn_date), 'start of month') AS last_month
        FROM customer_transactions
        GROUP BY customer_id
    ),

    -- 3. generate continuous list of months between first and last month (per customer)
    months(customer_id, month_first, last_month) AS (
        SELECT customer_id, first_month, last_month
        FROM   cust_span
        UNION ALL
        SELECT customer_id,
               DATE(month_first, '+1 month'),
               last_month
        FROM   months
        WHERE  DATE(month_first, '+1 month') <= last_month
    ),

    -- 4. max balance reached on any transaction date inside each month
    trans_month_max AS (
        SELECT
            customer_id,
            DATE(STRFTIME('%Y-%m-01', txn_date)) AS month_first,
            MAX(daily_balance)                   AS trans_max
        FROM running
        GROUP BY customer_id, month_first
    ),

    -- 5. balance carried into each month (last daily balance before the month starts)
    start_bal AS (
        SELECT
            m.customer_id,
            m.month_first,
            COALESCE(
                (
                    SELECT r.daily_balance
                    FROM   running r
                    WHERE  r.customer_id = m.customer_id
                       AND DATE(r.txn_date) < m.month_first
                    ORDER  BY DATE(r.txn_date) DESC
                    LIMIT  1
                ), 0
            ) AS opening_balance
        FROM months m
    ),

    -- 6. customer‑level monthly peak balance
    cust_month_peak AS (
        SELECT
            m.customer_id,
            m.month_first,
            MAX(COALESCE(t.trans_max, 0), s.opening_balance) AS month_peak
        FROM months m
        LEFT JOIN trans_month_max t
               ON t.customer_id = m.customer_id
              AND t.month_first = m.month_first
        JOIN start_bal s
              ON s.customer_id = m.customer_id
             AND s.month_first = m.month_first
    )

-- 7. final monthly total across all customers
SELECT
    STRFTIME('%Y-%m', month_first) AS month,
    SUM(month_peak)               AS total_max_daily_balance
FROM   cust_month_peak
GROUP  BY month
ORDER  BY month;