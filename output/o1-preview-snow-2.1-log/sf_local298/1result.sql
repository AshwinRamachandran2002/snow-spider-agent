WITH monthly_txns AS (
  SELECT
    "customer_id",
    DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD')) AS "txn_month",
    SUM("txn_amount") AS "monthly_txn_sum"
  FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
  GROUP BY
    "customer_id",
    DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))
),
cumulative AS (
  SELECT
    "customer_id",
    "txn_month",
    "monthly_txn_sum",
    SUM("monthly_txn_sum") OVER (
      PARTITION BY "customer_id"
      ORDER BY "txn_month"
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "cumulative_balance"
  FROM
    monthly_txns
),
balances AS (
  SELECT
    "txn_month",
    "customer_id",
    LAG("cumulative_balance") OVER (
      PARTITION BY "customer_id"
      ORDER BY "txn_month"
    ) AS "previous_balance"
  FROM
    cumulative
),
min_month AS (
  SELECT MIN(DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD'))) AS "min_month"
  FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
filtered_balances AS (
  SELECT
    "txn_month",
    COALESCE(GREATEST("previous_balance", 0), 0) AS "balance"
  FROM
    balances, min_month
  WHERE
    "previous_balance" IS NOT NULL
      AND "txn_month" > min_month."min_month"
),
total_balances AS (
  SELECT
    "txn_month",
    SUM("balance") AS "Total_Balance"
  FROM
    filtered_balances
  GROUP BY
    "txn_month"
)
SELECT
  TO_VARCHAR("txn_month", 'YYYY-MM') AS "Month",
  ROUND("Total_Balance", 4) AS "Total_Balance"
FROM
  total_balances
ORDER BY
  "Month" ASC;