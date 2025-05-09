WITH balances AS (
    /* month‑end balance for every customer & month in 2020 */
    SELECT
        customer_id,
        substr(txn_date,1,7) AS month,
        SUM(CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END) AS month_end_balance
    FROM customer_transactions
    WHERE txn_date BETWEEN '2020-01-01' AND '2020-12-31'
      AND txn_type IN ('deposit','withdrawal')
    GROUP BY customer_id, month
),
positive_counts AS (
    SELECT
        month,
        COUNT(CASE WHEN month_end_balance > 0 THEN 1 END) AS pos_cust_cnt
    FROM balances
    GROUP BY month
),
best_month AS (
    SELECT month
    FROM positive_counts
    ORDER BY pos_cust_cnt DESC, month
    LIMIT 1
),
worst_month AS (
    SELECT month
    FROM positive_counts
    ORDER BY pos_cust_cnt ASC, month
    LIMIT 1
),
best_avg AS (
    SELECT ROUND(AVG(month_end_balance),4) AS avg_bal
    FROM balances
    WHERE month = (SELECT month FROM best_month)
),
worst_avg AS (
    SELECT ROUND(AVG(month_end_balance),4) AS avg_bal
    FROM balances
    WHERE month = (SELECT month FROM worst_month)
),
results AS (
    SELECT 'most_positive' AS metric,
           (SELECT month FROM best_month)  AS month,
           (SELECT avg_bal FROM best_avg)  AS average_month_end_balance
    UNION ALL
    SELECT 'least_positive',
           (SELECT month FROM worst_month),
           (SELECT avg_bal FROM worst_avg)
    UNION ALL
    SELECT 'difference',
           NULL,
           ROUND( (SELECT avg_bal FROM best_avg) - (SELECT avg_bal FROM worst_avg), 4 )
)
SELECT metric, month, average_month_end_balance
FROM results
ORDER BY
    CASE metric
        WHEN 'most_positive' THEN 1
        WHEN 'least_positive' THEN 2
        ELSE 3
    END;