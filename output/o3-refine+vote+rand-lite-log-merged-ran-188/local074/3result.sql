/* Monthly closing balances – including months with no activity */
WITH RECURSIVE 

/* 1. earliest and latest months in the data --------------------*/
date_bounds AS (
    SELECT 
        date(min(txn_date), 'start of month') AS min_month,
        date(max(txn_date), 'start of month') AS max_month
    FROM customer_transactions
),

/* 2. calendar of months between those bounds ------------------*/
months(month_start) AS (
    SELECT min_month FROM date_bounds
    UNION ALL
    SELECT date(month_start, '+1 month')
    FROM   months, date_bounds
    WHERE  month_start < max_month
),

/* 3. list of customers ----------------------------------------*/
customers AS (
    SELECT DISTINCT customer_id
    FROM   customer_transactions
),

/* 4. customer × month grid ------------------------------------*/
customer_months AS (
    SELECT c.customer_id,
           m.month_start
    FROM   customers c
    CROSS  JOIN months    m
),

/* 5. net change per customer per month ------------------------*/
txn_monthly AS (
    SELECT
        customer_id,
        date(txn_date, 'start of month') AS month_start,
        SUM(
            CASE LOWER(txn_type)
                 WHEN 'deposit'    THEN  txn_amount
                 WHEN 'withdrawal' THEN -txn_amount
                 ELSE 0
            END
        ) AS monthly_change
    FROM customer_transactions
    GROUP BY customer_id, month_start
),

/* 6. merge grid with actual movements -------------------------*/
combined AS (
    SELECT
        cm.customer_id,
        cm.month_start,
        COALESCE(tm.monthly_change, 0) AS monthly_change
    FROM   customer_months cm
    LEFT   JOIN txn_monthly tm
           ON  cm.customer_id = tm.customer_id
          AND cm.month_start  = tm.month_start
)

/* 7. final result with running balance ------------------------*/
SELECT
    customer_id,
    strftime('%Y-%m', month_start)                     AS month,
    monthly_change,
    SUM(monthly_change) OVER (
        PARTITION BY customer_id
        ORDER BY     month_start
    )                                                  AS closing_balance
FROM   combined
ORDER BY customer_id, month_start;