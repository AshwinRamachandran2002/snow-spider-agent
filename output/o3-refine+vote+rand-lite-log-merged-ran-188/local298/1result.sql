WITH months AS (                               -- every YYYY-MM month that exists
    SELECT DISTINCT SUBSTR("txn_date", 1, 7) AS month
    FROM   "customer_transactions"
),
prev_balances AS (                             -- total (non-negative) balance as of 1st of each month
    SELECT m.month,
           (
               SELECT SUM(
                          CASE
                              WHEN b.balance < 0 THEN 0
                              ELSE b.balance
                          END
                        )
               FROM (
                       SELECT "customer_id",
                              SUM("txn_amount") AS balance
                       FROM   "customer_transactions"
                       WHERE  "txn_date" < m.month || '-01'   -- all history before the month starts
                       GROUP  BY "customer_id"
                    ) AS b
           ) AS total_prev_balance
    FROM   months AS m
)
SELECT   month                AS current_month,
         total_prev_balance   -- previous-month total across all users
FROM     prev_balances
WHERE    month > (SELECT MIN(month) FROM months)   -- drop the first calendar month
ORDER BY month;