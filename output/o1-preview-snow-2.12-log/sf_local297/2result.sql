WITH monthly_net_amounts AS (
  SELECT
    "customer_id",
    DATE_TRUNC('month', TO_DATE("txn_date", 'YYYY-MM-DD')) AS "month",
    SUM(
      CASE
        WHEN "txn_type" = 'deposit' THEN "txn_amount"
        WHEN "txn_type" = 'withdrawal' THEN -"txn_amount"
      END
    ) AS "monthly_net_amount"
  FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
  WHERE
    "txn_type" IN ('deposit', 'withdrawal')
  GROUP BY
    "customer_id",
    "month"
),
customer_monthly_balances AS (
  SELECT
    "customer_id",
    "month",
    "monthly_net_amount",
    SUM("monthly_net_amount") OVER (
      PARTITION BY "customer_id"
      ORDER BY "month" ROWS UNBOUNDED PRECEDING
    ) AS "closing_balance"
  FROM
    monthly_net_amounts
),
customer_balances_ranked AS (
  SELECT
    "customer_id",
    "month",
    "closing_balance",
    ROW_NUMBER() OVER (
      PARTITION BY "customer_id"
      ORDER BY "month" DESC NULLS LAST
    ) AS "month_rank"
  FROM
    customer_monthly_balances
),
customer_growth_rates AS (
  SELECT
    cb1."customer_id",
    cb1."month" AS "current_month",
    cb1."closing_balance" AS "current_balance",
    cb2."month" AS "previous_month",
    cb2."closing_balance" AS "previous_balance",
    CASE
      WHEN cb2."closing_balance" IS NULL OR cb2."closing_balance" = 0 THEN
        cb1."closing_balance" * 100
      ELSE
        ((cb1."closing_balance" - cb2."closing_balance") / cb2."closing_balance") * 100
    END AS "growth_rate"
  FROM
    customer_balances_ranked cb1
    LEFT JOIN customer_balances_ranked cb2 ON cb1."customer_id" = cb2."customer_id"
    AND cb1."month_rank" = 1
    AND cb2."month_rank" = 2
  WHERE
    cb1."month_rank" = 1
)
SELECT
  ROUND(
    (SUM(CASE WHEN "growth_rate" > 5 THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
    4
  ) AS "Percentage_of_customers"
FROM
  customer_growth_rates;