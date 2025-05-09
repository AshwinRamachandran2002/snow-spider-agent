WITH months AS (
    SELECT DISTINCT SUBSTR("txn_date", 1, 7) AS "month"
    FROM "customer_transactions"
),
customers AS (
    SELECT DISTINCT "customer_id"
    FROM "customer_transactions"
),
customer_months AS (
    SELECT c."customer_id", m."month"
    FROM customers c CROSS JOIN months m
),
monthly_changes AS (
    SELECT
        "customer_id",
        SUBSTR("txn_date", 1, 7) AS "month",
        ROUND(SUM(
            CASE
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ), 4) AS "monthly_change"
    FROM "customer_transactions"
    GROUP BY "customer_id", "month"
),
customer_balances AS (
    SELECT
        cm."customer_id",
        cm."month",
        COALESCE(mc."monthly_change", 0.0000) AS "monthly_change"
    FROM customer_months cm
    LEFT JOIN monthly_changes mc
    ON cm."customer_id" = mc."customer_id" AND cm."month" = mc."month"
),
customer_balances_with_cumulative AS (
    SELECT
        cb."customer_id",
        cb."month",
        cb."monthly_change",
        ROUND(SUM(cb."monthly_change") OVER (
            PARTITION BY cb."customer_id"
            ORDER BY cb."month"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 4) AS "cumulative_balance"
    FROM customer_balances cb
)
SELECT
    "customer_id",
    "month",
    "cumulative_balance" AS "closing_balance",
    "monthly_change",
    "cumulative_balance"
FROM customer_balances_with_cumulative
ORDER BY "customer_id", "month";