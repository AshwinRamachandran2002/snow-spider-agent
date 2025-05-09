WITH customers AS (
  SELECT DISTINCT "customer_id" FROM "customer_transactions"
),
months AS (
  SELECT '2020-01' AS "year_month"
  UNION ALL SELECT '2020-02'
  UNION ALL SELECT '2020-03'
  UNION ALL SELECT '2020-04'
),
customer_months AS (
  SELECT
    c."customer_id",
    m."year_month"
  FROM
    customers c CROSS JOIN months m
),
month_end_balances AS (
  SELECT
    cm."customer_id",
    cm."year_month",
    COALESCE(SUM(
      CASE
        WHEN ct."txn_type" = 'deposit' THEN ct."txn_amount"
        WHEN ct."txn_type" = 'withdrawal' THEN - ct."txn_amount"
        ELSE 0
      END
    ), 0) AS "month_end_balance"
  FROM
    customer_months cm
  LEFT JOIN "customer_transactions" ct ON
    ct."customer_id" = cm."customer_id"
    AND STRFTIME('%Y-%m', ct."txn_date") = cm."year_month"
    AND ct."txn_date" BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY
    cm."customer_id",
    cm."year_month"
),
positive_balance_counts AS (
  SELECT
    "year_month",
    COUNT(CASE WHEN "month_end_balance" > 0 THEN 1 END) AS "positive_balance_customers"
  FROM
    month_end_balances
  GROUP BY
    "year_month"
),
max_min_months AS (
  SELECT
    MAX("positive_balance_customers") AS max_customers,
    MIN("positive_balance_customers") AS min_customers
  FROM
    positive_balance_counts
),
max_month AS (
  SELECT "year_month"
  FROM positive_balance_counts
  WHERE "positive_balance_customers" = (SELECT max_customers FROM max_min_months)
  ORDER BY "year_month" ASC
  LIMIT 1
),
min_month AS (
  SELECT "year_month"
  FROM positive_balance_counts
  WHERE "positive_balance_customers" = (SELECT min_customers FROM max_min_months)
  ORDER BY "year_month" ASC
  LIMIT 1
),
average_balances AS (
  SELECT
    "year_month",
    AVG("month_end_balance") AS "average_balance"
  FROM
    month_end_balances
  WHERE
    "year_month" IN ((SELECT "year_month" FROM max_month), (SELECT "year_month" FROM min_month))
  GROUP BY
    "year_month"
)
SELECT
  ROUND(ABS(
    (SELECT "average_balance" FROM average_balances WHERE "year_month" = (SELECT "year_month" FROM max_month)) -
    (SELECT "average_balance" FROM average_balances WHERE "year_month" = (SELECT "year_month" FROM min_month))
  ), 4) AS "difference";