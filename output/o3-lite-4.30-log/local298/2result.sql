WITH daily_net AS (           
    SELECT
        txn_date,
        SUM(
            CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -1 * txn_amount
                ELSE 0
            END
        ) AS net_amount
    FROM customer_transactions
    GROUP BY txn_date
),
running_bal AS (              
    SELECT
        txn_date,
        SUM(net_amount) OVER (ORDER BY txn_date) AS total_balance
    FROM daily_net
),
month_starts AS (             
    SELECT
        substr(txn_date,1,7) AS month,          
        total_balance
    FROM running_bal
    WHERE substr(txn_date,9,2) = '01'           
),
with_prev AS (                
    SELECT
        month,
        LAG(total_balance) OVER (ORDER BY month) AS prev_month_balance
    FROM month_starts
)
SELECT
    month,
    CASE 
        WHEN prev_month_balance < 0 THEN 0
        ELSE prev_month_balance
    END AS total_balance_prev_month
FROM with_prev
WHERE prev_month_balance IS NOT NULL
ORDER BY month;