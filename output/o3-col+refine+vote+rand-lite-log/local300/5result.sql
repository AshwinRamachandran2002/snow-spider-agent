WITH RECURSIVE

-- 1. Earliest and latest transaction date per customer
bounds AS (
    SELECT  "customer_id",
            MIN( DATE("txn_date") ) AS start_date,
            MAX( DATE("txn_date") ) AS end_date
    FROM    "customer_transactions"
    GROUP BY "customer_id"
),

-- 2. Daily calendar for each customer between their first and last txn date
calendar(customer_id, day, end_date) AS (
    SELECT  customer_id,
            start_date,
            end_date
    FROM    bounds
    UNION ALL
    SELECT  customer_id,
            DATE(day,'+1 day'),
            end_date
    FROM    calendar
    WHERE   day < end_date
),

-- 3. Net value movement for each customer-day (+deposit, –withdrawal/purchase)
net AS (
    SELECT  "customer_id",
            DATE("txn_date") AS day,
            SUM( CASE 
                    WHEN "txn_type" = 'deposit'          THEN  1
                    ELSE                                    -1
                 END * "txn_amount") AS change
    FROM    "customer_transactions"
    GROUP BY "customer_id", day
),

-- 4. Full daily series with 0 change on non-activity days
daily AS (
    SELECT  c.customer_id,
            c.day,
            COALESCE(n.change,0) AS change
    FROM    calendar c
    LEFT JOIN net n
           ON n.customer_id = c.customer_id
          AND n.day         = c.day
),

-- 5. Running balance per customer (negatives floored to 0)
running AS (
    SELECT  customer_id,
            day,
            MAX(0,
                SUM(change) OVER (
                    PARTITION BY customer_id
                    ORDER BY day
                )
            ) AS daily_balance
    FROM    daily
),

-- 6. Maximum daily balance each customer achieved in every month
cust_month_max AS (
    SELECT  customer_id,
            STRFTIME('%Y-%m', day) AS month,
            MAX(daily_balance)     AS max_balance_in_month
    FROM    running
    GROUP BY customer_id, month
)

-- 7. Monthly total of those customer-level maxima
SELECT  month,
        SUM(max_balance_in_month) AS monthly_total_max_balance
FROM    cust_month_max
GROUP BY month
ORDER BY month;