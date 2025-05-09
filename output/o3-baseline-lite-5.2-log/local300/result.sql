WITH RECURSIVE
/* 1. Normalise transactions and set + / - sign */
cust_txns AS (
    SELECT
        customer_id,
        DATE(txn_date)                 AS txn_date,
        CASE
            WHEN LOWER(txn_type) = 'deposit'    THEN  txn_amount
            WHEN LOWER(txn_type) = 'withdrawal' THEN -txn_amount
            ELSE 0
        END                           AS amount
    FROM customer_transactions
),
/* 2. Get each customer’s overall date range */
cust_range AS (
    SELECT
        customer_id,
        MIN(txn_date) AS min_date,
        MAX(txn_date) AS max_date
    FROM cust_txns
    GROUP BY customer_id
),
/* 3. Build a complete calendar for every customer */
recursive_dates(customer_id, the_date, max_date) AS (
        SELECT customer_id,
               min_date,
               max_date
        FROM   cust_range
        UNION ALL
        SELECT customer_id,
               DATE(the_date, '+1 day'),
               max_date
        FROM   recursive_dates
        WHERE  the_date < max_date
),
/* 4. Net movement for each customer‑day (may be 0) */
daily_amounts AS (
    SELECT
        customer_id,
        txn_date      AS the_date,
        SUM(amount)   AS net_amount
    FROM cust_txns
    GROUP BY customer_id, txn_date
),
/* 5. Merge calendar with movements */
daily_balances AS (
    SELECT
        d.customer_id,
        d.the_date,
        COALESCE(a.net_amount, 0) AS net_amount
    FROM   recursive_dates d
    LEFT JOIN daily_amounts a
           ON a.customer_id = d.customer_id
          AND a.the_date    = d.the_date
),
/* 6. Cumulative (running) balance per customer */
running_balances AS (
    SELECT
        customer_id,
        the_date,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY      the_date
        ) AS cum_balance
    FROM daily_balances
),
/* 7. Adjust negatives to zero */
adjusted_balances AS (
    SELECT
        customer_id,
        the_date,
        CASE WHEN cum_balance < 0 THEN 0 ELSE cum_balance END AS daily_balance
    FROM running_balances
),
/* 8. Maximum balance each month per customer */
monthly_max AS (
    SELECT
        customer_id,
        strftime('%Y-%m', the_date)            AS month,
        MAX(daily_balance)                     AS max_daily_balance
    FROM adjusted_balances
    GROUP BY customer_id, month
),
/* 9. Sum of those maximums for each month */
monthly_total AS (
    SELECT
        month,
        SUM(max_daily_balance) AS monthly_total_balance
    FROM monthly_max
    GROUP BY month
)
SELECT
    month,
    monthly_total_balance
FROM monthly_total
ORDER BY month;