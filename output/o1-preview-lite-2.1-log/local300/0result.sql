WITH transaction_adjustments AS (
    SELECT
        "customer_id",
        "txn_date",
        CASE
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
            ELSE 0
        END AS "balance_change"
    FROM "customer_transactions"
),
cumulative_balances AS (
    SELECT
        "customer_id",
        "txn_date",
        SUM("balance_change") OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date"
            ROWS UNBOUNDED PRECEDING
        ) AS "cumulative_balance",
        STRFTIME('%Y-%m', "txn_date") AS "month"
    FROM transaction_adjustments
),
daily_balances AS (
    SELECT
        "customer_id",
        "month",
        CASE WHEN "cumulative_balance" < 0 THEN 0 ELSE "cumulative_balance" END AS "adjusted_daily_balance"
    FROM cumulative_balances
),
max_daily_balances AS (
    SELECT
        "customer_id",
        "month",
        MAX(ROUND("adjusted_daily_balance", 4)) AS "max_daily_balance"
        FROM daily_balances
    GROUP BY "customer_id", "month"
),
monthly_totals AS (
    SELECT
        "month",
        SUM("max_daily_balance") AS "total_max_daily_balance"
    FROM max_daily_balances
    GROUP BY "month"
)
SELECT
    "month" AS "Month",
    ROUND("total_max_daily_balance", 4) AS "Total_Max_Daily_Balance"
FROM monthly_totals
ORDER BY "month";