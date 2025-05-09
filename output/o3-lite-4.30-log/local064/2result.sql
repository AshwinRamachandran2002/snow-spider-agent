WITH monthly_balances AS (
    SELECT
        customer_id,
        SUBSTR(txn_date,1,7)                       AS month,
        SUM(CASE
                WHEN txn_type = 'deposit'     THEN  txn_amount
                WHEN txn_type = 'withdrawal'  THEN -txn_amount
            END)                                AS month_end_balance
    FROM customer_transactions
    WHERE txn_date LIKE '2020-%'
    GROUP BY customer_id, month
),
positive_counts AS (
    SELECT
        month,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 END) AS positive_cust_cnt
    FROM monthly_balances
    GROUP BY month
),
max_month AS (
    SELECT month
    FROM positive_counts
    ORDER BY positive_cust_cnt DESC, month
    LIMIT 1
),
min_month AS (
    SELECT month
    FROM positive_counts
    ORDER BY positive_cust_cnt ASC, month
    LIMIT 1
),
avg_balances AS (
    SELECT
        month,
        ROUND(AVG(month_end_balance),4) AS avg_balance
    FROM monthly_balances
    WHERE month IN (SELECT month FROM max_month UNION SELECT month FROM min_month)
    GROUP BY month
),
diff AS (
    SELECT ROUND(
             (SELECT avg_balance FROM avg_balances WHERE month = (SELECT month FROM max_month))
             -
             (SELECT avg_balance FROM avg_balances WHERE month = (SELECT month FROM min_month))
           ,4) AS diff_value
)
SELECT 'max_positive_month' AS metric,
       (SELECT month FROM max_month)                    AS month,
       (SELECT printf('%.4f',avg_balance) FROM avg_balances WHERE month = (SELECT month FROM max_month)) AS average_month_end_balance
UNION ALL
SELECT 'min_positive_month',
       (SELECT month FROM min_month),
       (SELECT printf('%.4f',avg_balance) FROM avg_balances WHERE month = (SELECT month FROM min_month))
UNION ALL
SELECT 'difference',
       NULL,
       printf('%.4f', diff_value)
FROM diff;