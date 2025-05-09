WITH
dates(date) AS (
    SELECT DATE('2020-01-01') AS date
    UNION ALL
    SELECT DATE(date, '+1 day')
    FROM dates
    WHERE date < (SELECT MAX("txn_date") FROM "customer_transactions")
),
customers AS (
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),
customer_dates AS (
    SELECT c.customer_id, d.date AS txn_date
    FROM customers c
    CROSS JOIN dates d
),
daily_net_changes AS (
    SELECT "customer_id", "txn_date",
        SUM(CASE WHEN "txn_type" = 'deposit' THEN "txn_amount"
                 WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                 ELSE 0 END) AS daily_net_change
    FROM "customer_transactions"
    GROUP BY "customer_id", "txn_date"
),
customer_balances AS (
    SELECT cd.customer_id, cd.txn_date,
        COALESCE(dnc.daily_net_change, 0) AS daily_net_change
    FROM customer_dates cd
    LEFT JOIN daily_net_changes dnc
        ON cd.customer_id = dnc.customer_id AND cd.txn_date = dnc.txn_date
),
cumulative_balances AS (
    SELECT customer_id, txn_date,
        SUM(daily_net_change) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_balance
    FROM customer_balances
),
avg_balances AS (
    SELECT customer_id, txn_date, cumulative_balance,
        strftime('%Y-%m', txn_date) AS txn_month,
        AVG(cumulative_balance) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS avg_balance_30d
    FROM cumulative_balances
)
SELECT txn_month AS "Month", ROUND(SUM(max_avg_balance_30d), 4) AS "Total_Max_Daily_Avg_Balance"
FROM (
    SELECT customer_id, txn_month, MAX(avg_balance_30d) AS max_avg_balance_30d
    FROM avg_balances
    WHERE txn_month != '2020-01'
    GROUP BY customer_id, txn_month
) AS customer_monthly_max
GROUP BY txn_month
ORDER BY txn_month;