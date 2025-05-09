WITH
monthly_balances AS (
    SELECT
      "customer_id",
      SUBSTRING("txn_date", 1, 7) AS "year_month",
      SUM(
        CASE
          WHEN "txn_type" = 'deposit' THEN "txn_amount"
          WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
          ELSE 0
        END
      ) AS "month_end_balance"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    WHERE "txn_date" LIKE '2020%'
    GROUP BY "customer_id", "year_month"
),
positive_counts AS (
    SELECT
      "year_month",
      COUNT(*) AS "positive_customer_count"
    FROM monthly_balances
    WHERE "month_end_balance" > 0
    GROUP BY "year_month"
),
average_balances AS (
    SELECT
      "year_month",
      AVG("month_end_balance") AS "average_month_end_balance"
    FROM monthly_balances
    GROUP BY "year_month"
),
counts_and_averages AS (
    SELECT 
      p."year_month",
      p."positive_customer_count",
      a."average_month_end_balance"
    FROM positive_counts p
    JOIN average_balances a ON p."year_month" = a."year_month"
),
max_positive_count AS (
    SELECT MAX("positive_customer_count") AS "max_count" FROM counts_and_averages
),
min_positive_count AS (
    SELECT MIN("positive_customer_count") AS "min_count" FROM counts_and_averages
),
highest_count_month AS (
    SELECT "year_month", "average_month_end_balance" 
    FROM counts_and_averages 
    WHERE "positive_customer_count" = (SELECT "max_count" FROM max_positive_count)
    ORDER BY "year_month" FETCH FIRST 1 ROWS ONLY
),
lowest_count_month AS (
    SELECT "year_month", "average_month_end_balance" 
    FROM counts_and_averages 
    WHERE "positive_customer_count" = (SELECT "min_count" FROM min_positive_count)
    ORDER BY "year_month" FETCH FIRST 1 ROWS ONLY
)
SELECT
  ROUND(ABS(
    (SELECT "average_month_end_balance" FROM highest_count_month) -
    (SELECT "average_month_end_balance" FROM lowest_count_month)
  ), 4) AS "Difference_between_averages";