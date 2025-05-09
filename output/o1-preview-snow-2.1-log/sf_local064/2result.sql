WITH monthly_balances AS (
  SELECT
    "customer_id",
    TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY-MM') AS "year_month",
    SUM("txn_amount") AS "monthly_balance"
  FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
  WHERE
    "txn_date" >= '2020-01-01' AND "txn_date" <= '2020-12-31'
  GROUP BY
    "customer_id",
    "year_month"
),
positive_balances AS (
  SELECT
    "year_month",
    COUNT(DISTINCT "customer_id") AS "positive_customers",
    AVG("monthly_balance") AS "average_balance"
  FROM
    monthly_balances
  WHERE
    "monthly_balance" > 0
  GROUP BY
    "year_month"
),
most_customers_month AS (
  SELECT
    "year_month",
    "average_balance"
  FROM
    positive_balances
  ORDER BY
    "positive_customers" DESC NULLS LAST
  LIMIT 1
),
fewest_customers_month AS (
  SELECT
    "year_month",
    "average_balance"
  FROM
    positive_balances
  ORDER BY
    "positive_customers" ASC NULLS LAST
  LIMIT 1
)
SELECT
  ROUND(most."average_balance" - fewest."average_balance", 4) AS "Difference_in_Average_Month_End_Balance"
FROM
  most_customers_month most,
  fewest_customers_month fewest
;