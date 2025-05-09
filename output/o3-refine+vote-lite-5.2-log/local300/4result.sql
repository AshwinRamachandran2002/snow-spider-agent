WITH RECURSIVE
/* 1. net movement for each customer on each transaction date */
daily_txn AS (
    SELECT
        customer_id,
        DATE(txn_date) AS txn_date,
        SUM(
            CASE
                WHEN LOWER(txn_type) = 'deposit'     THEN  txn_amount
                WHEN LOWER(txn_type) = 'withdrawal'  THEN -txn_amount
                ELSE 0
            END
        ) AS daily_net
    FROM customer_transactions
    GROUP BY customer_id,
             DATE(txn_date)
),
/* 2. first and last transaction date per customer */
customer_range AS (
    SELECT
        customer_id,
        MIN(DATE(txn_date)) AS start_date,
        MAX(DATE(txn_date)) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),
/* 3. one row for every calendar day between first and last txn (recursive) */
date_series AS (
    SELECT
        customer_id,
        start_date AS the_date,
        end_date
    FROM customer_range
    UNION ALL
    SELECT
        customer_id,
        DATE(the_date, '+1 day'),
        end_date
    FROM date_series
    WHERE the_date < end_date
),
/* 4. attach daily net movement (0 if none) */
customer_calendar AS (
    SELECT
        ds.customer_id,
        ds.the_date,
        COALESCE(dt.daily_net, 0) AS daily_net
    FROM date_series ds
    LEFT JOIN daily_txn dt
           ON dt.customer_id = ds.customer_id
          AND dt.txn_date    = ds.the_date
),
/* 5. running balance before zero‑flooring */
running_balances AS (
    SELECT
        customer_id,
        the_date,
        SUM(daily_net) OVER (
            PARTITION BY customer_id
            ORDER BY the_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_balance
    FROM customer_calendar
),
/* 6. replace negative balances with 0 */
running_balances_clean AS (
    SELECT
        customer_id,
        the_date,
        CASE
            WHEN cumulative_balance < 0 THEN 0
            ELSE cumulative_balance
        END AS daily_balance
    FROM running_balances
),
/* 7. highest daily balance per customer‑month */
monthly_max_balance AS (
    SELECT
        customer_id,
        STRFTIME('%Y-%m', the_date) AS month_ym,
        MAX(daily_balance)          AS max_daily_balance
    FROM running_balances_clean
    GROUP BY customer_id,
             month_ym
)
/* 8. total of those peak balances for each month */
SELECT
    month_ym                             AS month,
    SUM(max_daily_balance)               AS total_max_daily_balance
FROM monthly_max_balance
GROUP BY month_ym
ORDER BY month_ym;