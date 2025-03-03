WITH months AS (
  SELECT DISTINCT strftime('%Y-%m', "txn_date") AS "month"
  FROM "customer_transactions"
  WHERE strftime('%Y-%m', "txn_date") > (
    SELECT MIN(strftime('%Y-%m', "txn_date")) FROM "customer_transactions"
  )
),
month_end_dates AS (
  SELECT
    "month",
    date("month" || '-01', '-1 day') AS "previous_month_end"
  FROM months
),
customer_balances AS (
  SELECT
    me."month",
    ct."customer_id",
    SUM(ct."txn_amount") AS "balance"
  FROM month_end_dates me
  JOIN "customer_transactions" ct
    ON ct."txn_date" <= me."previous_month_end"
  GROUP BY me."month", ct."customer_id"
),
balance_per_month AS (
  SELECT
    "month",
    SUM(CASE WHEN "balance" < 0 THEN 0 ELSE "balance" END) AS "total_balance"
  FROM customer_balances
  GROUP BY "month"
)
SELECT "month" AS "Month", "total_balance" AS "Total_Balance"
FROM balance_per_month
ORDER BY "Month" ASC;