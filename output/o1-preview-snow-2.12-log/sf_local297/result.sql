WITH monthly_nets AS (
  SELECT
    TRY_TO_NUMBER("customer_id") AS "customer_id",
    DATE_TRUNC('month', TRY_TO_DATE("txn_date", 'YYYY-MM-DD')) AS "month_start",
    SUM(
      CASE
        WHEN LOWER("txn_type") = 'deposit' THEN TRY_TO_NUMBER("txn_amount")
        WHEN LOWER("txn_type") = 'withdrawal' THEN -TRY_TO_NUMBER("txn_amount")
        ELSE 0
      END
    ) AS "monthly_net_amount"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
  WHERE
    TRY_TO_DATE("txn_date", 'YYYY-MM-DD') IS NOT NULL AND
    TRY_TO_NUMBER("txn_amount") IS NOT NULL AND
    TRY_TO_NUMBER("customer_id") IS NOT NULL
  GROUP BY
    TRY_TO_NUMBER("customer_id"),
    DATE_TRUNC('month', TRY_TO_DATE("txn_date", 'YYYY-MM-DD'))
),
monthly_closing_balances AS (
  SELECT
    "customer_id",
    "month_start",
    "monthly_net_amount",
    SUM("monthly_net_amount") OVER (
      PARTITION BY "customer_id"
      ORDER BY "month_start" ASC NULLS LAST
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "closing_balance"
  FROM monthly_nets
),
growth_rates AS (
  SELECT
    "customer_id",
    "month_start",
    "closing_balance",
    LAG("closing_balance") OVER (
      PARTITION BY "customer_id"
      ORDER BY "month_start" ASC NULLS LAST
    ) AS "prev_closing_balance",
    CASE
      WHEN LAG("closing_balance") OVER (
        PARTITION BY "customer_id"
        ORDER BY "month_start" ASC NULLS LAST
      ) = 0 OR LAG("closing_balance") OVER (
        PARTITION BY "customer_id"
        ORDER BY "month_start" ASC NULLS LAST
      ) IS NULL THEN "closing_balance" * 100
      ELSE ("closing_balance" - LAG("closing_balance") OVER (
        PARTITION BY "customer_id"
        ORDER BY "month_start" ASC NULLS LAST
      )) / ABS(LAG("closing_balance") OVER (
        PARTITION BY "customer_id"
        ORDER BY "month_start" ASC NULLS LAST
      )) * 100
    END AS "growth_rate"
  FROM monthly_closing_balances
),
most_recent_growth AS (
  SELECT
    "customer_id",
    "growth_rate",
    ROW_NUMBER() OVER (
      PARTITION BY "customer_id"
      ORDER BY "month_start" DESC NULLS LAST
    ) AS rn
  FROM growth_rates
)
SELECT
  ROUND(
    (COUNT(CASE WHEN "growth_rate" > 5 THEN 1 END) * 100.0) / COUNT(*),
    4
  ) AS "Percentage_of_customers"
FROM most_recent_growth
WHERE rn = 1;