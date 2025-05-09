WITH month_net AS (          -- 1. monthly net deposits (+) / withdrawals (‑)
    SELECT
        customer_id,
        DATE(STRFTIME('%Y-%m-01', txn_date)) AS month_start,
        SUM(CASE 
                WHEN txn_type = 'deposit'     THEN  txn_amount
                WHEN txn_type = 'withdrawal'  THEN -txn_amount
                ELSE 0
            END) AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, month_start
),
month_balance AS (           -- 2. running (closing) balance per month
    SELECT
        customer_id,
        month_start,
        net_amount,
        SUM(net_amount) OVER (
            PARTITION BY customer_id 
            ORDER BY month_start
        ) AS closing_balance
    FROM month_net
),
month_with_growth AS (       -- 3. add previous‑month balance
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id 
            ORDER BY month_start
        ) AS prev_balance
    FROM month_balance
),
most_recent AS (             -- 4. keep only the most‑recent month per customer
    SELECT  m1.*
    FROM    month_with_growth m1
    JOIN   (SELECT customer_id,
                   MAX(month_start) AS max_month
            FROM   month_with_growth
            GROUP  BY customer_id) m2
      ON  m1.customer_id = m2.customer_id 
     AND  m1.month_start = m2.max_month
),
growth_flag AS (             -- 5. compute growth rate for the latest month
    SELECT
        customer_id,
        CASE 
            WHEN COALESCE(prev_balance,0) = 0
                 THEN closing_balance * 100.0
            ELSE (closing_balance - prev_balance) * 100.0 / prev_balance
        END AS growth_rate_pct
    FROM most_recent
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate_pct > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    ,4) AS pct_customers_growth_gt_5
FROM growth_flag;