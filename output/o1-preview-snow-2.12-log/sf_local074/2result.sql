WITH customer_ids AS (
  SELECT DISTINCT "customer_id"
  FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
months AS (
  SELECT DISTINCT TO_DATE(SUBSTR("txn_date", 1, 7) || '-01', 'YYYY-MM-DD') AS "month_date"
  FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
customer_months AS (
  SELECT c."customer_id", m."month_date"
  FROM customer_ids c
  CROSS JOIN months m
),
txn_signed AS (
  SELECT
    "customer_id",
    TO_DATE(SUBSTR("txn_date", 1, 7) || '-01', 'YYYY-MM-DD') AS "month_date",
    CASE
      WHEN "txn_type" = 'deposit' THEN "txn_amount"
      ELSE -1 * "txn_amount"
    END AS "amount_signed"
  FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
monthly_changes AS (
  SELECT
    cm."customer_id",
    cm."month_date",
    COALESCE(SUM(ts."amount_signed"), 0) AS "monthly_change"
  FROM customer_months cm
  LEFT JOIN txn_signed ts
    ON cm."customer_id" = ts."customer_id" AND cm."month_date" = ts."month_date"
  GROUP BY cm."customer_id", cm."month_date"
),
monthly_balances AS (
  SELECT
    "customer_id",
    TO_CHAR("month_date", 'YYYY-MM') AS "month",
    ROUND("monthly_change", 4) AS "monthly_change",
    ROUND(SUM("monthly_change") OVER (
      PARTITION BY "customer_id"
      ORDER BY "month_date"
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 4) AS "cumulative_balance"
  FROM monthly_changes
)
SELECT
  "customer_id",
  "month",
  "monthly_change",
  "cumulative_balance"
FROM monthly_balances
ORDER BY "customer_id", "month";