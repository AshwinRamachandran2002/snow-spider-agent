WITH date_limits AS (
  SELECT
    MIN(TO_DATE("txn_date", 'YYYY-MM-DD')) AS "min_date",
    MAX(TO_DATE("txn_date", 'YYYY-MM-DD')) AS "max_date"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
),
dates AS (
  SELECT
    DATEADD(day, ROW_NUMBER() OVER (ORDER BY NULL) - 1, dl."min_date") AS "date"
  FROM TABLE(GENERATOR(ROWCOUNT => 1000))
  CROSS JOIN date_limits dl
  QUALIFY "date" <= dl."max_date"
),
customers AS (
  SELECT DISTINCT "customer_id"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
),
customer_dates AS (
  SELECT
    c."customer_id",
    d."date"
  FROM customers c
  CROSS JOIN dates d
),
txn_amounts AS (
  SELECT
    "customer_id",
    TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_date",
    CASE
      WHEN "txn_type" = 'deposit' THEN "txn_amount"
      ELSE - "txn_amount"
    END AS "txn_amount"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
),
balance_per_day AS (
  SELECT
    cd."customer_id",
    cd."date",
    SUM(COALESCE(ta."txn_amount", 0)) OVER (
      PARTITION BY cd."customer_id"
      ORDER BY cd."date"
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "balance"
  FROM customer_dates cd
  LEFT JOIN txn_amounts ta
    ON cd."customer_id" = ta."customer_id" AND cd."date" = ta."txn_date"
),
avg_balance_30_days AS (
  SELECT
    "customer_id",
    "date",
    AVG("balance") OVER (
      PARTITION BY "customer_id"
      ORDER BY "date"
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS "avg_balance"
  FROM balance_per_day
),
monthly_user_max_avg_balances AS (
  SELECT
    DATE_TRUNC('month', "date") AS "month",
    "customer_id",
    MAX("avg_balance") AS "max_avg_balance"
  FROM avg_balance_30_days
  GROUP BY 1, 2
),
first_month AS (
  SELECT MIN("month") AS "first_month"
  FROM monthly_user_max_avg_balances
),
result AS (
  SELECT
    "month",
    SUM("max_avg_balance") AS "total_max_avg_balance"
  FROM monthly_user_max_avg_balances
  WHERE "month" > (SELECT "first_month" FROM first_month)
  GROUP BY "month"
  ORDER BY "month"
)
SELECT
  TO_CHAR("month", 'YYYY-MM-DD') AS "Month",
  ROUND("total_max_avg_balance", 4) AS "Total_Max_Daily_Average"
FROM result;