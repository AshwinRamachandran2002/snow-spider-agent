WITH month_list AS (                       -- all distinct months present
    SELECT DISTINCT DATE(strftime('%Y-%m-01', "txn_date")) AS month_start
    FROM "customer_transactions"
),
ordered_months AS (                        -- order the months chronologically
    SELECT month_start,
           ROW_NUMBER() OVER (ORDER BY month_start) AS rn
    FROM month_list
),
snapshots AS (                             -- exclude the very first month (baseline)
    SELECT month_start
    FROM ordered_months
    WHERE rn > 1
),
customer_balances AS (                     -- balance per customer up to each snapshot date
    SELECT s.month_start,
           ct.customer_id,
           SUM(
               CASE
                   WHEN ct.txn_type = 'deposit'          THEN  ct.txn_amount
                   ELSE                                        -ct.txn_amount   -- treat withdrawals & purchases as negative
               END
           ) AS raw_balance
    FROM snapshots AS s
    JOIN "customer_transactions" AS ct
         ON DATE(ct.txn_date) < s.month_start
    GROUP BY s.month_start, ct.customer_id
),
totals AS (                                -- replace negatives with zero and sum
    SELECT month_start,
           SUM(
               CASE
                   WHEN raw_balance < 0 THEN 0
                   ELSE raw_balance
               END
           ) AS total_balance_prev_month
    FROM customer_balances
    GROUP BY month_start
)
SELECT DATE(month_start) AS month,
       total_balance_prev_month
FROM totals
ORDER BY month;