WITH monthly_balances AS (               -- step 1: month-end balance for every customer & month
    SELECT
        customer_id,
        substr(txn_date,1,7)                          AS month_yyyy_mm,
        SUM(CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END)                                     AS month_end_balance
    FROM customer_transactions
    WHERE txn_date LIKE '2020-%'
    GROUP BY customer_id,
             substr(txn_date,1,7)
),
positive_counts AS (                    -- step 2: count customers with positive balance per month
    SELECT
        month_yyyy_mm,
        COUNT(*) AS positive_customer_cnt
    FROM monthly_balances
    WHERE month_end_balance > 0
    GROUP BY month_yyyy_mm
),
highest_month AS (                      -- month with MOST positive-balance customers
    SELECT month_yyyy_mm
    FROM positive_counts
    ORDER BY positive_customer_cnt DESC, month_yyyy_mm
    LIMIT 1
),
lowest_month AS (                       -- month with FEWEST positive-balance customers
    SELECT month_yyyy_mm
    FROM positive_counts
    ORDER BY positive_customer_cnt ASC, month_yyyy_mm
    LIMIT 1
),
avg_highest AS (                        -- step 3a: average balance in the highest month
    SELECT AVG(month_end_balance) AS avg_balance
    FROM monthly_balances
    WHERE month_yyyy_mm = (SELECT month_yyyy_mm FROM highest_month)
),
avg_lowest AS (                         -- step 3b: average balance in the lowest month
    SELECT AVG(month_end_balance) AS avg_balance
    FROM monthly_balances
    WHERE month_yyyy_mm = (SELECT month_yyyy_mm FROM lowest_month)
)
SELECT                                    -- step 4: difference between the two averages
       (SELECT avg_balance FROM avg_highest) -
       (SELECT avg_balance FROM avg_lowest)  AS difference_between_averages;