WITH monthly_balances AS (
  SELECT
    "customer_id",
    DATE(SUBSTR("txn_date", 1, 7) || '-01') AS "month_start",
    SUM(CASE
          WHEN "txn_type" = 'deposit' THEN "txn_amount"
          WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
          ELSE 0
        END) AS "monthly_net_amount"
  FROM "customer_transactions"
  GROUP BY "customer_id", "month_start"
),
cumulative_balances AS (
  SELECT
    "customer_id",
    "month_start",
    "monthly_net_amount",
    SUM("monthly_net_amount") OVER (PARTITION BY "customer_id" ORDER BY "month_start") AS "closing_balance",
    ROW_NUMBER() OVER (PARTITION BY "customer_id" ORDER BY "month_start" DESC) AS "rnum_desc"
  FROM monthly_balances
),
customer_growth AS (
  SELECT
    mb_recent."customer_id",
    mb_recent."month_start" AS "recent_month",
    mb_recent."closing_balance" AS "recent_balance",
    mb_prior."month_start" AS "prior_month",
    mb_prior."closing_balance" AS "prior_balance"
  FROM
    cumulative_balances AS mb_recent
    LEFT JOIN cumulative_balances AS mb_prior
      ON mb_recent."customer_id" = mb_prior."customer_id"
     AND mb_prior."rnum_desc" = mb_recent."rnum_desc" + 1
  WHERE mb_recent."rnum_desc" = 1
),
customer_growth_rates AS (
  SELECT
    "customer_id",
    CASE WHEN COALESCE("prior_balance", 0) = 0 THEN
      "recent_balance" * 100
    ELSE
      (("recent_balance" - "prior_balance") * 100.0) / ABS("prior_balance")
    END AS "growth_rate"
  FROM customer_growth
)
SELECT
  (COUNT(CASE WHEN "growth_rate" > 5 THEN 1 END) * 100.0) / COUNT(*) AS "percentage_of_customers"
FROM customer_growth_rates;