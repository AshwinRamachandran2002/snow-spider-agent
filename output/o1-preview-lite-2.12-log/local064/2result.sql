WITH monthly_balances AS (
  SELECT
    "customer_id",
    SUBSTR("txn_date", 1, 7) AS "month",
    SUM(
      CASE
        WHEN "txn_type" = 'deposit' THEN "txn_amount"
        WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
        ELSE 0
      END
    ) AS "month_end_balance"
  FROM "customer_transactions"
  WHERE "txn_date" LIKE '2020-%'
  GROUP BY "customer_id", "month"
),
positive_counts AS (
  SELECT
    "month",
    COUNT(*) AS "positive_customer_count"
  FROM monthly_balances
  WHERE "month_end_balance" > 0
  GROUP BY "month"
),
highest_month AS (
  SELECT "month" FROM positive_counts ORDER BY "positive_customer_count" DESC LIMIT 1
),
lowest_month AS (
  SELECT "month" FROM positive_counts ORDER BY "positive_customer_count" ASC LIMIT 1
),
average_balances AS (
  SELECT
    "month",
    AVG("month_end_balance") AS "average_balance"
  FROM monthly_balances
  GROUP BY "month"
)
SELECT
  ROUND(
    ABS(
      (SELECT "average_balance" FROM average_balances WHERE "month" = (SELECT "month" FROM highest_month)) -
      (SELECT "average_balance" FROM average_balances WHERE "month" = (SELECT "month" FROM lowest_month))
    )
  , 4) AS "difference";