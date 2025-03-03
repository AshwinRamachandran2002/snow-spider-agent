WITH month_end_balances AS (
    SELECT
        "customer_id",
        SUBSTR("txn_date", 1, 7) AS "month",
        SUM(
            CASE
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS "month_end_balance"
    FROM "customer_transactions"
    WHERE "txn_date" LIKE '2020%'
    GROUP BY "customer_id", "month"
),
month_positive_balances AS (
    SELECT
        "month",
        COUNT(*) AS positive_balance_customers
    FROM month_end_balances
    WHERE "month_end_balance" > 0
    GROUP BY "month"
),
max_customers_value AS (
    SELECT MAX(positive_balance_customers) AS max_customers FROM month_positive_balances
),
min_customers_value AS (
    SELECT MIN(positive_balance_customers) AS min_customers FROM month_positive_balances
),
max_months AS (
    SELECT "month" FROM month_positive_balances WHERE positive_balance_customers = (SELECT max_customers FROM max_customers_value)
),
min_months AS (
    SELECT "month" FROM month_positive_balances WHERE positive_balance_customers = (SELECT min_customers FROM min_customers_value)
),
avg_balance_max_month AS (
    SELECT AVG("month_end_balance") AS avg_balance
    FROM month_end_balances
    WHERE "month" IN (SELECT "month" FROM max_months)
),
avg_balance_min_month AS (
    SELECT AVG("month_end_balance") AS avg_balance
    FROM month_end_balances
    WHERE "month" IN (SELECT "month" FROM min_months)
)
SELECT ROUND(ABS((SELECT avg_balance FROM avg_balance_max_month) - (SELECT avg_balance FROM avg_balance_min_month)), 4) AS difference;