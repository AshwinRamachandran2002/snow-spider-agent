WITH monthly_net AS (            -- 1️⃣ net movement per customer & month (YYYY-MM-01)
    SELECT customer_id,
           SUBSTR(txn_date,1,7) || '-01' AS month_start,
           SUM(
               CASE txn_type
                    WHEN 'deposit'     THEN  txn_amount      -- +ve
                    WHEN 'withdrawal'  THEN -txn_amount      -- -ve
                    ELSE 0                                  
               END
           ) AS net_amount
    FROM customer_transactions
    GROUP BY customer_id,
             SUBSTR(txn_date,1,7) || '-01'
),
running_balance AS (             -- 2️⃣ cumulative closing balance
    SELECT customer_id,
           month_start,
           SUM(net_amount) OVER (PARTITION BY customer_id
                                 ORDER BY month_start) AS closing_balance
    FROM monthly_net
),
ranked_months AS (               -- 3️⃣ rank months (1 = most-recent)
    SELECT customer_id,
           month_start,
           closing_balance,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY month_start DESC) AS rn
    FROM running_balance
),
growth AS (                      -- 4️⃣ calculate growth versus prior month
    SELECT  cur.customer_id,
            CASE
                 WHEN prev.closing_balance IS NULL
                      OR prev.closing_balance = 0
                      THEN cur.closing_balance * 100.0
                 ELSE (cur.closing_balance - prev.closing_balance)
                      * 100.0 / ABS(prev.closing_balance)
            END AS growth_rate_pct
    FROM ranked_months AS cur
    LEFT JOIN ranked_months AS prev
           ON cur.customer_id = prev.customer_id
          AND prev.rn         = 2          -- previous month
    WHERE cur.rn = 1                       -- keep most-recent month only
)
SELECT ROUND(                               -- 5️⃣ final percentage of customers >5%
           100.0 * SUM(CASE WHEN growth_rate_pct > 5 THEN 1 ELSE 0 END)
                 / COUNT(*)
       , 4) AS pct_customers_gt_5
FROM   growth;