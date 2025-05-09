WITH month_net AS (              -- 1. monthly net deposits (+) & withdrawals (–)
    SELECT
        customer_id,
        DATE(SUBSTR(txn_date,1,7) || '-01')  AS month_start,
        SUM(CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END)                            AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, month_start
),
closing AS (                     -- 2. running (cumulative) closing balance
    SELECT
        customer_id,
        month_start,
        net_amount,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                         AS closing_balance
    FROM month_net
),
latest AS (                      -- 3. isolate each customer’s latest month & prior balance
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        )                         AS prev_balance
    FROM closing
),
growth AS (                      -- 4. compute latest-month growth rate per customer
    SELECT
        customer_id,
        CASE
             WHEN COALESCE(prev_balance,0) = 0
                  THEN closing_balance * 100.0
             ELSE (closing_balance - prev_balance) * 100.0 / ABS(prev_balance)
        END                      AS growth_rate_percent
    FROM latest
    WHERE month_start = (SELECT MAX(month_start)
                         FROM closing c2
                         WHERE c2.customer_id = latest.customer_id)
)
-- 5. overall % of customers whose most-recent growth rate > 5 %
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate_percent > 5 THEN 1 ELSE 0 END)
        / COUNT(DISTINCT customer_id),
        4
    ) AS percent_customers_growth_gt_5
FROM growth;