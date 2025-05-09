WITH adjusted_transactions AS (
    SELECT 
        "customer_id",
        TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_date",
        CASE 
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
            ELSE 0
        END AS "adjusted_amount"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
cumulative_balances AS (
    SELECT
        "customer_id",
        "txn_date",
        SUM("adjusted_amount") OVER (PARTITION BY "customer_id" ORDER BY "txn_date") AS "balance"
    FROM adjusted_transactions
),
daily_balances_zeroed AS (
    SELECT
        "customer_id",
        "txn_date",
        GREATEST("balance", 0) AS "balance"
    FROM cumulative_balances
),
monthly_max_balances AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', "txn_date") AS "month",
        MAX("balance") AS "max_balance"
    FROM daily_balances_zeroed
    GROUP BY "customer_id", DATE_TRUNC('month', "txn_date")
),
monthly_total_max_balances AS (
    SELECT
        "month",
        SUM("max_balance") AS "total_max_balance"
    FROM monthly_max_balances
    GROUP BY "month"
)
SELECT 
    TO_CHAR("month", 'YYYY-MM') AS "Month",
    ROUND("total_max_balance", 4) AS "Total_Max_Daily_Balance"
FROM monthly_total_max_balances
ORDER BY "month";