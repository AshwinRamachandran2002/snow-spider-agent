WITH RECURSIVE
    -- 1. convert every transaction into a signed amount
    norm_txn AS (
        SELECT
            customer_id,
            DATE(txn_date) AS txn_date,
            CASE
                WHEN LOWER(txn_type) = 'deposit'    THEN  txn_amount
                WHEN LOWER(txn_type) = 'withdrawal' THEN -txn_amount
                ELSE 0
            END AS signed_amount
        FROM customer_transactions
    ),

    -- 2. first and last month in the data
    range AS (
        SELECT
            DATE(STRFTIME('%Y-%m-01', MIN(txn_date))) AS first_month,
            DATE(STRFTIME('%Y-%m-01', MAX(txn_date))) AS last_month
        FROM norm_txn
    ),

    -- 3. continuous month calendar between the extremes above
    calendar(month_start) AS (
        SELECT first_month FROM range
        UNION ALL
        SELECT DATE(month_start, '+1 month')
        FROM calendar, range
        WHERE month_start < last_month
    ),

    -- 4. list of all customers
    customers AS (
        SELECT DISTINCT customer_id FROM customer_transactions
    ),

    -- 5. every (customer, month) pair
    cust_months AS (
        SELECT c.customer_id, cal.month_start
        FROM customers c
        CROSS JOIN calendar cal
    ),

    -- 6. net change (delta) per customer per month
    monthly_change AS (
        SELECT
            customer_id,
            DATE(STRFTIME('%Y-%m-01', txn_date)) AS month_start,
            SUM(signed_amount)                   AS month_delta
        FROM norm_txn
        GROUP BY customer_id, month_start
    ),

    -- 7. ensure a row for every month (fill with 0 when no activity)
    dense_frame AS (
        SELECT
            cm.customer_id,
            cm.month_start,
            COALESCE(mc.month_delta, 0) AS monthly_change
        FROM cust_months cm
        LEFT JOIN monthly_change mc
               ON  mc.customer_id = cm.customer_id
               AND mc.month_start  = cm.month_start
    ),

    -- 8. running / closing balance
    running_bal AS (
        SELECT
            customer_id,
            month_start,
            monthly_change,
            SUM(monthly_change) OVER (
                PARTITION BY customer_id
                ORDER BY month_start
            ) AS closing_balance
        FROM dense_frame
    )

SELECT
    customer_id,
    STRFTIME('%Y-%m', month_start) AS month_year,
    monthly_change,
    closing_balance
FROM running_bal
ORDER BY customer_id, month_start;