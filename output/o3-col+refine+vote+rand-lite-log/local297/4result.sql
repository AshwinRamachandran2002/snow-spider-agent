WITH monthly AS (                       -- 1. net movement per month (1st day)
    SELECT
        customer_id,
        date(substr(txn_date,1,7) || '-01') AS month_start,   -- YYYY-MM-01
        SUM(CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
            END)                            AS monthly_net
    FROM customer_transactions
    WHERE txn_type IN ('deposit','withdrawal')
    GROUP BY customer_id, month_start
),
running_bal AS (                       -- 2. cumulative balance by customer
    SELECT
        customer_id,
        month_start,
        monthly_net,
        SUM(monthly_net) OVER (PARTITION BY customer_id
                               ORDER BY month_start) AS closing_balance
    FROM monthly
),
ranked AS (                            -- 3. latest and previous month per customer
    SELECT
        customer_id,
        month_start,
        closing_balance,
        ROW_NUMBER() OVER (PARTITION BY customer_id
                           ORDER BY month_start DESC) AS rnk
    FROM running_bal
),
growth AS (                            -- 4. growth rate on most-recent month
    SELECT
        cur.customer_id,
        CASE
            WHEN IFNULL(prev.closing_balance,0) = 0
                 THEN cur.closing_balance * 100.0
            ELSE (cur.closing_balance - prev.closing_balance)
                 * 100.0 / prev.closing_balance
        END AS growth_rate
    FROM ranked AS cur
    LEFT JOIN ranked AS prev
           ON cur.customer_id = prev.customer_id
          AND prev.rnk = 2                    -- prior month
    WHERE cur.rnk = 1                         -- latest month only
)
-- 5. percentage of customers with growth_rate > 5 %
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) 
        / COUNT(*)
    , 2) AS percentage_customers_growth_gt_5
FROM growth;