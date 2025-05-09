WITH monthly_net AS (
  SELECT
    "customer_id",
    DATE(STRFTIME('%Y-%m-01', "txn_date")) AS "month_first_day",
    SUM(CASE 
          WHEN "txn_type" = 'deposit' THEN "txn_amount"
          ELSE - "txn_amount"
        END) AS "net_amount"
  FROM
    "customer_transactions"
  GROUP BY 
    "customer_id",
    "month_first_day"
),
monthly_balances AS (
  SELECT
    "customer_id",
    "month_first_day",
    "net_amount",
    SUM("net_amount") OVER (PARTITION BY "customer_id" ORDER BY "month_first_day") AS "closing_balance"
  FROM
    monthly_net
),
customer_latest_two_months AS (
  SELECT
    "customer_id",
    "month_first_day",
    "closing_balance",
    ROW_NUMBER() OVER (PARTITION BY "customer_id" ORDER BY "month_first_day" DESC) AS rn
  FROM
    monthly_balances
),
customer_recent_balances AS (
  SELECT 
    "customer_id",
    MAX(CASE WHEN rn = 1 THEN "closing_balance" END) AS current_balance,
    MAX(CASE WHEN rn = 2 THEN "closing_balance" END) AS previous_balance
  FROM
    customer_latest_two_months
  GROUP BY
    "customer_id"
  HAVING COUNT(*) = 2
),
growth_rates AS (
  SELECT 
    "customer_id",
    current_balance,
    previous_balance,
    CASE
      WHEN previous_balance = 0 THEN current_balance * 100.0
      ELSE (current_balance - previous_balance) * 100.0 / previous_balance
    END AS growth_rate
  FROM
    customer_recent_balances
)
SELECT
  ROUND(100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) / COUNT(*), 4) AS "percentage_of_customers"
FROM
  growth_rates;