WITH monthly_net AS (          -- 1.  net movement for each customer & month (1st day)
    SELECT 
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date"))              AS month_start,
        SUM(CASE WHEN LOWER("txn_type") = 'deposit' 
                 THEN "txn_amount" 
                 ELSE -1 * "txn_amount" 
            END)                                              AS net_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", month_start
),  

closing_balances AS (          -- 2. running balance per customer
    SELECT
        "customer_id",
        month_start,
        net_amount,
        SUM(net_amount) 
            OVER (PARTITION BY "customer_id" 
                  ORDER BY month_start 
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
                                                              AS closing_balance
    FROM monthly_net
),  

growth_by_month AS (           -- 3. closing-balance growth vs prior month
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        LAG(closing_balance) 
            OVER (PARTITION BY "customer_id" ORDER BY month_start) AS prev_closing_balance
    FROM closing_balances
),  

growth_rates AS (              -- 4. growth-rate calculation
    SELECT
        "customer_id",
        month_start,
        CASE 
            WHEN prev_closing_balance = 0 OR prev_closing_balance IS NULL
                 THEN closing_balance * 100
            ELSE (closing_balance - prev_closing_balance) / prev_closing_balance * 100
        END                                                      AS growth_rate
    FROM growth_by_month
),  

latest_growth AS (             -- 5. most-recent month per customer
    SELECT
        "customer_id",
        growth_rate,
        ROW_NUMBER() 
            OVER (PARTITION BY "customer_id" ORDER BY month_start DESC) AS rn
    FROM growth_rates
)  

-- 6. percentage of customers whose latest growth > 5 %
SELECT 
    ROUND(100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) 
                 / COUNT(*), 4)     AS "PCT_CUSTOMERS_GT_5PCT_GROWTH"
FROM latest_growth
WHERE rn = 1;