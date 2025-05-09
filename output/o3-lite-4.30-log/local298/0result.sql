WITH month_list AS (
    SELECT DISTINCT DATE(strftime('%Y-%m-01', "txn_date")) AS month_start
    FROM "customer_transactions"
),
ordered_months AS (
    SELECT 
        month_start,
        ROW_NUMBER() OVER (ORDER BY month_start) AS rn
    FROM month_list
),
customer_balances AS (
    SELECT 
        om.month_start,
        ct.customer_id,
        SUM(ct.txn_amount) AS balance
    FROM ordered_months AS om
    JOIN "customer_transactions" AS ct
      ON DATE(ct.txn_date) < om.month_start
    GROUP BY 
        om.month_start,
        ct.customer_id
),
monthly_totals AS (
    SELECT 
        month_start,
        SUM(CASE WHEN balance < 0 THEN 0 ELSE balance END) AS total_balance_prev_month
    FROM customer_balances
    GROUP BY month_start
)
SELECT 
    strftime('%Y-%m', month_start) AS month,
    total_balance_prev_month
FROM monthly_totals
WHERE month_start IN (
    SELECT month_start FROM ordered_months WHERE rn > 1
)
ORDER BY month_start;