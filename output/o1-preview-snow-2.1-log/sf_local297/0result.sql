WITH latest_txn_date AS (
  SELECT MAX(TO_DATE("txn_date", 'YYYY-MM-DD')) AS "max_txn_date"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
current_month_start AS (
  SELECT DATE_TRUNC('month', "max_txn_date") AS "current_month_start"
  FROM latest_txn_date
),
dates AS (
  SELECT
    "current_month_start",
    DATEADD(day, -1, "current_month_start") AS "prev_balance_date",
    DATEADD(month, -1, "current_month_start") AS "prev_month_start",
    DATEADD(day, -1, DATEADD(month, -1, "current_month_start")) AS "prev_prev_balance_date"
  FROM current_month_start
),
balances AS (
  SELECT
    ct."customer_id",
    SUM(CASE WHEN TO_DATE(ct."txn_date", 'YYYY-MM-DD') BETWEEN TO_DATE('1900-01-01', 'YYYY-MM-DD') AND d."prev_prev_balance_date"
             THEN CASE WHEN LOWER(ct."txn_type") = 'deposit' THEN ct."txn_amount"
                       WHEN LOWER(ct."txn_type") = 'withdrawal' THEN -ct."txn_amount"
                       ELSE 0 END
             ELSE 0 END) AS "prev_balance",
    SUM(CASE WHEN TO_DATE(ct."txn_date", 'YYYY-MM-DD') BETWEEN TO_DATE('1900-01-01', 'YYYY-MM-DD') AND d."prev_balance_date"
             THEN CASE WHEN LOWER(ct."txn_type") = 'deposit' THEN ct."txn_amount"
                       WHEN LOWER(ct."txn_type") = 'withdrawal' THEN -ct."txn_amount"
                       ELSE 0 END
             ELSE 0 END) AS "current_balance"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS ct
  CROSS JOIN dates d
  GROUP BY ct."customer_id"
),
growth_rates AS (
  SELECT
    "customer_id",
    "prev_balance",
    "current_balance",
    CASE
      WHEN "prev_balance" = 0 AND "current_balance" <> 0 THEN "current_balance" * 100
      WHEN "prev_balance" = 0 AND "current_balance" = 0 THEN 0
      ELSE (("current_balance" - "prev_balance") / "prev_balance") * 100
    END AS "growth_rate"
  FROM balances
)
SELECT
  ROUND((COUNT(CASE WHEN "growth_rate" > 5 THEN 1 END) * 100.0) / NULLIF(COUNT(*), 0), 4) AS "Percentage_of_users_with_growth_rate_over_5_percent"
FROM growth_rates;