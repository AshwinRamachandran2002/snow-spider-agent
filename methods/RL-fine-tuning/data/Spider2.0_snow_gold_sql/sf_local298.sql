WITH base_data AS (
    SELECT
        "customer_id",
        TRY_TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_date",
        CASE
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
            ELSE 0
        END AS "signed_amount"
    FROM
        BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),
customer_cumulative AS (
    SELECT
        "customer_id",
        "txn_date",
        SUM("signed_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_balance"
    FROM
        base_data
),
monthly_balances AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', "txn_date") AS "txn_month",
        LAST_VALUE("cumulative_balance") OVER (
            PARTITION BY "customer_id", DATE_TRUNC('month', "txn_date")
            ORDER BY "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS "month_end_balance"
    FROM
        customer_cumulative
),
monthly_balances_distinct AS (
    SELECT DISTINCT
        "customer_id",
        "txn_month",
        "month_end_balance"
    FROM
        monthly_balances
),
previous_month_balances AS (
    SELECT
        "customer_id",
        DATEADD(month, 1, "txn_month") AS "month",
        "month_end_balance" AS "previous_month_balance"
    FROM
        monthly_balances_distinct
),
min_month AS (
    SELECT MIN("month") AS "min_month" FROM previous_month_balances
),
final_balances AS (
    SELECT
        "month",
        SUM(GREATEST(COALESCE("previous_month_balance", 0), 0)) AS "Total_Balance"
    FROM
        previous_month_balances
    WHERE
        "month" > (SELECT "min_month" FROM min_month)
    GROUP BY
        "month"
)
SELECT
    TO_CHAR("month", 'YYYY-MM') AS "Month",
    ROUND("Total_Balance", 4) AS "Total_Balance"
FROM
    final_balances
ORDER BY
    "Month";