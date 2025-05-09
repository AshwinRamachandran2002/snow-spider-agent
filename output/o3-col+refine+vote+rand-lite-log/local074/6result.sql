WITH months AS (   -- every year-month that appears in the ledger
    SELECT DISTINCT substr(txn_date,1,7) AS year_month
    FROM customer_transactions
),
customers AS (     -- every customer that appears in the ledger
    SELECT DISTINCT customer_id
    FROM customer_transactions
),
calendar AS (      -- cross-join so every customer has every month
    SELECT c.customer_id,
           m.year_month
    FROM customers c
    CROSS JOIN months m
),
monthly_change AS (  -- net change (deposit – withdrawal) per month
    SELECT customer_id,
           substr(txn_date,1,7) AS year_month,
           SUM(CASE
                   WHEN txn_type = 'deposit'    THEN  txn_amount
                   WHEN txn_type = 'withdrawal' THEN -txn_amount
               END) AS change_amt
    FROM customer_transactions
    GROUP BY customer_id, substr(txn_date,1,7)
)
SELECT cal.customer_id,
       cal.year_month,
       COALESCE(mc.change_amt,0)                                        AS monthly_change,
       COALESCE( (SELECT SUM(CASE
                                 WHEN ct.txn_type = 'deposit'    THEN  ct.txn_amount
                                 WHEN ct.txn_type = 'withdrawal' THEN -ct.txn_amount
                             END)
                  FROM customer_transactions AS ct
                  WHERE ct.customer_id = cal.customer_id
                    AND substr(ct.txn_date,1,7) <= cal.year_month
                 ), 0)                                                  AS cumulative_balance
FROM calendar AS cal
LEFT JOIN monthly_change AS mc
       ON  mc.customer_id = cal.customer_id
       AND mc.year_month  = cal.year_month
ORDER BY cal.customer_id,
         cal.year_month;