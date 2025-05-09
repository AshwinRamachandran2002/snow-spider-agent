WITH
-- 1. identify the overall first and last month appearing in the data
date_bounds AS (
    SELECT
        date(min("txn_date"))  AS min_date,
        date(max("txn_date"))  AS max_date
    FROM "customer_transactions"
),

-- 2. build a complete, gap‑free list of month starts between the bounds
months AS (
    SELECT strftime('%Y-%m-01', min_date) AS month_start
    FROM date_bounds
    UNION ALL
    SELECT strftime('%Y-%m-01', date(month_start, '+1 month'))
    FROM months, date_bounds
    WHERE month_start < strftime('%Y-%m-01', max_date)
),

-- 3. list of every customer appearing in the ledger
customers AS (
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),

-- 4. every customer × every month (ensures months with no activity are kept)
customer_month_grid AS (
    SELECT  c.customer_id,
            m.month_start
    FROM customers c
    CROSS JOIN months  m
),

-- 5. month‑level net movement per customer
monthly_movements AS (
    SELECT
        customer_id,
        strftime('%Y-%m-01', "txn_date")           AS month_start,
        SUM(
            CASE
                WHEN lower("txn_type") = 'deposit'      THEN  txn_amount        -- deposits add
                WHEN lower("txn_type") = 'withdrawal'   THEN -txn_amount        -- withdrawals subtract
                ELSE txn_amount                         -- fallback: treat others as positive
            END
        ) AS monthly_change
    FROM "customer_transactions"
    GROUP BY customer_id, month_start
),

-- 6. attach the movements to the full customer‑month grid, defaulting to 0
customer_month_balances AS (
    SELECT
        g.customer_id,
        g.month_start,
        COALESCE(m.monthly_change, 0) AS monthly_change
    FROM customer_month_grid g
    LEFT JOIN monthly_movements m
           ON  m.customer_id = g.customer_id
           AND m.month_start = g.month_start
)

-- 7. final report: month‑by‑month change and running (closing) balance
SELECT
    customer_id,
    strftime('%Y-%m', month_start)                AS month_year,
    monthly_change,
    ROUND( SUM(monthly_change)
           OVER (PARTITION BY customer_id
                 ORDER BY month_start
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2
    )                                             AS closing_balance
FROM   customer_month_balances
ORDER  BY customer_id,
          month_start;