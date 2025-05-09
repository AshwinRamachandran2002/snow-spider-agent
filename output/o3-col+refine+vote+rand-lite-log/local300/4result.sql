WITH RECURSIVE
/* 1. Net change (deposit +, withdrawal -) per customer per transaction date */
txn_change AS (
    SELECT customer_id,
           txn_date,
           SUM(
               CASE txn_type
                    WHEN 'deposit'    THEN  txn_amount
                    WHEN 'withdrawal' THEN -txn_amount
                    ELSE 0
               END
           ) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, txn_date
),
/* 2. Earliest and latest transaction dates for each customer */
spans AS (
    SELECT customer_id,
           MIN(txn_date) AS start_date,
           MAX(txn_date) AS end_date
    FROM customer_transactions
    GROUP BY customer_id
),
/* 3. Calendar of every day between start_date and end_date (inclusive) */
calendar(customer_id, cal_date) AS (
    SELECT customer_id, start_date
    FROM spans
    UNION ALL
    SELECT customer_id,
           DATE(cal_date, '+1 day')
    FROM calendar
    JOIN spans USING (customer_id)
    WHERE DATE(cal_date, '+1 day') <= spans.end_date
),
/* 4. Running daily balance, negative values replaced with zero */
daily_balance AS (
    SELECT  c.customer_id,
            c.cal_date,
            MAX(
                0,
                SUM(COALESCE(t.net_change,0))
                OVER (
                    PARTITION BY c.customer_id
                    ORDER BY     c.cal_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
            ) AS balance
    FROM calendar c
    LEFT JOIN txn_change t
           ON t.customer_id = c.customer_id
          AND t.txn_date    = c.cal_date
),
/* 5. Highest balance each customer reached in every month */
customer_month_max AS (
    SELECT  customer_id,
            STRFTIME('%Y-%m', cal_date)      AS year_month,
            MAX(balance)                     AS max_daily_balance_in_month
    FROM    daily_balance
    GROUP BY customer_id, year_month
)
/* 6. Monthly total of those customer-level maximum balances */
SELECT  year_month,
        SUM(max_daily_balance_in_month) AS monthly_total_max_balances
FROM    customer_month_max
GROUP BY year_month
ORDER BY year_month;