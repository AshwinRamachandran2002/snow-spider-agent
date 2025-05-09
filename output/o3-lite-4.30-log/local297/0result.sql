WITH monthly_net AS (
    SELECT
        customer_id,
        DATE(txn_date, 'start of month') AS month_start,
        SUM(CASE WHEN txn_type = 'deposit'
                 THEN txn_amount
                 ELSE -txn_amount
            END) AS monthly_net
    FROM customer_transactions
    WHERE txn_type IN ('deposit', 'withdrawal')
    GROUP BY customer_id, DATE(txn_date, 'start of month')
),
closing_balances AS (
    SELECT
        customer_id,
        month_start,
        SUM(monthly_net) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        ) AS closing_balance,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month_start DESC
        ) AS rn
    FROM monthly_net
),
pivot AS (
    SELECT
        customer_id,
        MAX(CASE WHEN rn = 1 THEN closing_balance END) AS current_bal,
        MAX(CASE WHEN rn = 2 THEN closing_balance END) AS prev_bal
    FROM closing_balances
    GROUP BY customer_id
),
growth AS (
    SELECT
        customer_id,
        CASE
            WHEN IFNULL(prev_bal, 0) = 0
                 THEN current_bal * 100.0
            ELSE (current_bal - prev_bal) * 100.0 / ABS(prev_bal)
        END AS growth_rate
    FROM pivot
),
totals AS (
    SELECT
        COUNT(*) AS total_customers,
        SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) AS good_growth
    FROM growth
)
SELECT
    ROUND(good_growth * 100.0 / total_customers, 4) AS percentage_of_customers_with_growth_rate_gt_5
FROM totals;