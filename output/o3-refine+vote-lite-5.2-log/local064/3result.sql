WITH txn_2020 AS (   -- keep only 2020 transactions and give each a signed amount
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)   AS txn_month,
        CASE 
            WHEN LOWER(txn_type) = 'deposit'    THEN  txn_amount
            WHEN LOWER(txn_type) = 'withdrawal' THEN -txn_amount
            ELSE 0
        END                            AS signed_amt
    FROM customer_transactions
    WHERE substr(txn_date,1,4) = '2020'
),

month_balances AS (   -- month‑end balance per customer per month
    SELECT
        customer_id,
        txn_month,
        SUM(signed_amt) AS month_end_balance
    FROM txn_2020
    GROUP BY customer_id, txn_month
),

month_stats AS (      -- positive‑balance counts and average balance per month
    SELECT
        txn_month,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END) AS positive_custs,
        AVG(month_end_balance)                                  AS avg_balance
    FROM month_balances
    GROUP BY txn_month
),

max_min AS (          -- identify the “best” and “worst” months
    SELECT
        -- month with the HIGHEST number of positive‑balance customers
        (SELECT txn_month FROM month_stats 
         ORDER BY positive_custs DESC, txn_month LIMIT 1)              AS max_month,
        (SELECT positive_custs FROM month_stats 
         ORDER BY positive_custs DESC, txn_month LIMIT 1)              AS max_positive_custs,
        (SELECT avg_balance FROM month_stats 
         ORDER BY positive_custs DESC, txn_month LIMIT 1)              AS max_avg_balance,
         
        -- month with the LOWEST number of positive‑balance customers
        (SELECT txn_month FROM month_stats 
         ORDER BY positive_custs ASC,  txn_month LIMIT 1)              AS min_month,
        (SELECT positive_custs FROM month_stats 
         ORDER BY positive_custs ASC,  txn_month LIMIT 1)              AS min_positive_custs,
        (SELECT avg_balance FROM month_stats 
         ORDER BY positive_custs ASC,  txn_month LIMIT 1)              AS min_avg_balance
)

SELECT
    max_month                    AS month_with_most_positive_balances,
    max_positive_custs           AS positive_customer_count_max,
    ROUND(max_avg_balance,4)     AS average_balance_max_month,
    
    min_month                    AS month_with_fewest_positive_balances,
    min_positive_custs           AS positive_customer_count_min,
    ROUND(min_avg_balance,4)     AS average_balance_min_month,
    
    ROUND(max_avg_balance - min_avg_balance,4) AS difference_between_averages
FROM max_min;