WITH
months("year_month") AS (
    SELECT DISTINCT SUBSTR("txn_date", 1, 7) AS "year_month"
    FROM "customer_transactions"
),
customers("customer_id") AS (
    SELECT DISTINCT "customer_id" FROM "customer_transactions"
),
customer_months AS (
    SELECT c."customer_id", m."year_month"
    FROM customers c
    CROSS JOIN months m
),
monthly_changes AS (
    SELECT "customer_id", SUBSTR("txn_date",1,7) AS "year_month",
           SUM(
               CASE
                   WHEN "txn_type" = 'deposit' THEN ROUND("txn_amount", 4)
                   ELSE ROUND(-"txn_amount", 4)
               END
           ) AS "monthly_change"
    FROM "customer_transactions"
    GROUP BY "customer_id", "year_month"
),
customer_balances AS (
    SELECT
        cm."customer_id",
        cm."year_month" AS "month",
        COALESCE(mc."monthly_change", 0) AS "monthly_change"
    FROM customer_months cm
    LEFT JOIN monthly_changes mc
        ON cm."customer_id" = mc."customer_id" AND cm."year_month" = mc."year_month"
),
balance_calculations AS (
    SELECT
        "customer_id",
        "month",
        "monthly_change",
        SUM("monthly_change") OVER (
            PARTITION BY "customer_id"
            ORDER BY "month"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_balance"
    FROM customer_balances
)
SELECT
    "customer_id",
    "month",
    ROUND("cumulative_balance", 4) AS "closing_balance",
    ROUND("monthly_change", 4) AS "monthly_change",
    ROUND("cumulative_balance", 4) AS "cumulative_balance"
FROM balance_calculations
ORDER BY "customer_id", "month";