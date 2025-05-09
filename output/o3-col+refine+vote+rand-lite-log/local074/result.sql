WITH 
-- 1. Build a month calendar spanning the whole transaction history
RECURSIVE months(month_start) AS (
    SELECT date(MIN(txn_date), 'start of month')
    FROM   customer_transactions
    UNION ALL
    SELECT date(month_start, '+1 month')
    FROM   months
    WHERE  month_start < date((SELECT MAX(txn_date) FROM customer_transactions),
                              'start of month')
),

-- 2. All customers that ever had a transaction
customers AS (
    SELECT DISTINCT customer_id
    FROM   customer_transactions
),

-- 3. Cartesian product → every customer × every calendar month
month_customer AS (
    SELECT  c.customer_id,
            strftime('%Y-%m', m.month_start) AS year_month
    FROM    customers c
    CROSS   JOIN months m
),

-- 4. Net change (+deposit, –withdrawal) per customer per month
monthly_change AS (
    SELECT  customer_id,
            substr(txn_date,1,7) AS year_month,
            SUM(CASE 
                    WHEN txn_type = 'deposit'    THEN  txn_amount
                    WHEN txn_type = 'withdrawal' THEN -txn_amount
                    ELSE 0 
                END) AS monthly_change
    FROM    customer_transactions
    GROUP   BY customer_id, year_month
),

-- 5. Overlay the changes onto the full grid; missing months default to 0
grid_with_change AS (
    SELECT  mc.customer_id,
            mc.year_month,
            COALESCE(mchg.monthly_change, 0) AS monthly_change
    FROM    month_customer mc
    LEFT    JOIN monthly_change mchg
           ON mc.customer_id = mchg.customer_id
          AND mc.year_month  = mchg.year_month
)

-- 6. Final report with cumulative (closing) balance
SELECT  customer_id,
        year_month,
        monthly_change,
        SUM(monthly_change) OVER (
            PARTITION BY customer_id
            ORDER BY year_month
        ) AS closing_balance
FROM    grid_with_change
ORDER BY customer_id,
         year_month;