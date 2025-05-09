WITH customer_txns AS (
    SELECT
        "customer_id",
        date("txn_date") AS "txn_date",
        "txn_amount"
    FROM "customer_transactions"
    WHERE "txn_date" BETWEEN '2020-01-01' AND '2020-12-31'
),
customer_txns_ordered AS (
    SELECT
        "customer_id",
        "txn_date",
        "txn_amount",
        strftime('%Y-%m', "txn_date") AS "year_month",
        SUM("txn_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_balance"
    FROM customer_txns
),
month_end_balances AS (
    SELECT
        "customer_id",
        "year_month",
        MAX("cumulative_balance") AS "month_end_balance"
    FROM customer_txns_ordered
    GROUP BY "customer_id", "year_month"
),
month_stats AS (
    SELECT
        "year_month",
        COUNT(DISTINCT "customer_id") AS "positive_balance_customers",
        AVG("month_end_balance") AS "average_month_end_balance"
    FROM month_end_balances
    WHERE "month_end_balance" > 0
    GROUP BY "year_month"
),
max_month AS (
    SELECT
        *
    FROM month_stats
    ORDER BY "positive_balance_customers" DESC
    LIMIT 1
),
min_month AS (
    SELECT
        *
    FROM month_stats
        ORDER BY "positive_balance_customers" ASC
    LIMIT 1
)
SELECT
    ROUND(ABS(max_month."average_month_end_balance" - min_month."average_month_end_balance"), 4) AS "difference_in_average_month_end_balance"
FROM max_month, min_month;