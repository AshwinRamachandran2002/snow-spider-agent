WITH
min_date AS (
   SELECT MIN("txn_date") AS "min_txn_date"
   FROM "customer_transactions"
),
max_date AS (
   SELECT MAX("txn_date") AS "max_txn_date"
   FROM "customer_transactions"
),
date_series(date) AS (
   SELECT min_txn_date FROM min_date
   UNION ALL
   SELECT DATE(date, '+1 day') FROM date_series
   WHERE date < (SELECT max_txn_date FROM max_date)
),
customer_dates AS (
   SELECT customer_id, date
   FROM (SELECT DISTINCT customer_id FROM "customer_transactions"), date_series
),
txn_net AS (
   SELECT customer_id, txn_date AS date,
          CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END AS net_amount
   FROM "customer_transactions"
),
daily_balances AS (
   SELECT cd.customer_id, cd.date, IFNULL(tn.net_amount, 0) AS net_amount
   FROM customer_dates cd
   LEFT JOIN txn_net tn
   ON cd.customer_id = tn.customer_id AND cd.date = tn.date
),
balance_calc AS (
   SELECT customer_id, date, net_amount,
          SUM(net_amount) OVER (
              PARTITION BY customer_id 
              ORDER BY date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) AS balance
       FROM daily_balances
),
avg_balance_calc AS (
   SELECT customer_id, date, balance,
          AVG(balance) OVER (
              PARTITION BY customer_id 
              ORDER BY date
              ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
          ) AS avg_30day_balance
       FROM balance_calc
),
max_avg_balance_per_month AS (
   SELECT customer_id, STRFTIME('%Y-%m', date) AS month, MAX(avg_30day_balance) AS max_avg_30day_balance
   FROM avg_balance_calc
   GROUP BY customer_id, month
)
SELECT month AS Month, ROUND(SUM(max_avg_30day_balance), 4) AS Total_Max_Daily_Avg_Balance
FROM max_avg_balance_per_month
WHERE month > (SELECT STRFTIME('%Y-%m', min_txn_date) FROM min_date)
GROUP BY month
ORDER BY month;