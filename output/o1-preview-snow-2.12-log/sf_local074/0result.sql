WITH date_range AS (
  SELECT 
    DATE_TRUNC('MONTH', MIN(TO_DATE("txn_date", 'YYYY-MM-DD'))) AS min_month,
    DATE_TRUNC('MONTH', MAX(TO_DATE("txn_date", 'YYYY-MM-DD'))) AS max_month
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
months AS (
  SELECT min_month AS month_start
  FROM date_range
  UNION ALL
  SELECT DATEADD(MONTH, 1, month_start)
  FROM months
  WHERE month_start < (SELECT max_month FROM date_range)
),
customers AS (
  SELECT DISTINCT "customer_id"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
customer_months AS (
  SELECT c."customer_id", m.month_start
  FROM customers c
  CROSS JOIN months m
),
transactions AS (
  SELECT
    "customer_id",
    TO_DATE("txn_date", 'YYYY-MM-DD') AS txn_date,
    LOWER("txn_type") AS txn_type,
    "txn_amount"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
transaction_signs AS (
  SELECT
    "customer_id",
    DATE_TRUNC('MONTH', txn_date) AS month_start,
    CASE 
      WHEN txn_type = 'deposit' THEN "txn_amount"
      WHEN txn_type IN ('withdrawal', 'purchase') THEN - "txn_amount"
      ELSE 0
    END AS signed_amount
  FROM transactions
),
monthly_changes AS (
  SELECT
    "customer_id",
    month_start,
    SUM(signed_amount) AS monthly_change
  FROM transaction_signs
  GROUP BY "customer_id", month_start
),
customer_monthly_balances AS (
  SELECT
    cm."customer_id",
    cm.month_start,
    COALESCE(mc.monthly_change, 0) AS monthly_change
  FROM customer_months cm
  LEFT JOIN monthly_changes mc
    ON cm."customer_id" = mc."customer_id" AND cm.month_start = mc.month_start
),
customer_balances AS (
  SELECT
    "customer_id",
    month_start,
    monthly_change,
    SUM(monthly_change) OVER (PARTITION BY "customer_id" ORDER BY month_start) AS cumulative_balance
  FROM customer_monthly_balances
)
SELECT 
  "customer_id",
  TO_CHAR(month_start, 'YYYY-MM') AS "month",
  ROUND(monthly_change, 4) AS monthly_change,
  ROUND(cumulative_balance, 4) AS cumulative_balance
FROM customer_balances
ORDER BY "customer_id", month_start;