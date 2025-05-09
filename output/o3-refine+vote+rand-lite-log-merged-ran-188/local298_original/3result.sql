WITH month_starts AS (                 -- every 1st‑of‑month that appears in the data
    SELECT DATE("txn_date",'start of month') AS month_start
    FROM   "customer_transactions"
    GROUP  BY month_start
),
customers AS (                         -- list of all customers
    SELECT DISTINCT "customer_id"
    FROM   "customer_transactions"
),
balance_per_customer AS (              -- running balance for every customer on the 1st of each month
    SELECT
        c.customer_id,
        m.month_start,
        COALESCE( (
            SELECT SUM(CASE                    -- deposits = + , everything else = –
                           WHEN ct.txn_type = 'deposit'
                           THEN  ct.txn_amount
                           ELSE -ct.txn_amount
                       END)
            FROM   "customer_transactions" ct
            WHERE  ct.customer_id = c.customer_id
              AND  DATE(ct.txn_date) < m.month_start   -- all txns prior to the 1st
        ), 0) AS balance
    FROM customers  c
    CROSS JOIN month_starts m
),
total_balance AS (                     -- total (with negative balances floored to zero)
    SELECT
        month_start,
        SUM(CASE WHEN balance < 0 THEN 0 ELSE balance END) AS total_balance
    FROM   balance_per_customer
    GROUP  BY month_start
),
final AS (                             -- shift forward one month
    SELECT
        tb.month_start AS month,
        (
          SELECT total_balance
          FROM   total_balance tb_prev
          WHERE  tb_prev.month_start = DATE(tb.month_start,'-1 month')
        ) AS prev_month_total
    FROM total_balance tb
)
SELECT
    month,
    prev_month_total AS total_balance
FROM   final
WHERE  prev_month_total IS NOT NULL     -- drop the very first month (baseline only)
ORDER  BY month;