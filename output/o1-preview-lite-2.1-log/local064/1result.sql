WITH customer_txns AS (
    SELECT
        "customer_id",
        "txn_date",
        "txn_amount",
        strftime('%Y-%m', "txn_date") AS "month"
    FROM "customer_transactions"
    WHERE strftime('%Y', "txn_date") = '2020'
),
customer_cumulative_balances AS (
    SELECT
        "customer_id",
        "txn_date",
        "txn_amount",
        "month",
        SUM("txn_amount") OVER (
            PARTITION BY "customer_id" 
            ORDER BY "txn_date", "txn_amount" 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_balance
    FROM customer_txns
),
month_end_balances AS (
    SELECT
        "customer_id",
        "month",
        cumulative_balance
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY "customer_id", "month" 
                ORDER BY "txn_date" DESC
            ) AS rn
        FROM customer_cumulative_balances
    )
    WHERE rn = 1
),
positive_balances AS (
    SELECT
        "customer_id",
        "month",
        cumulative_balance
    FROM month_end_balances
    WHERE cumulative_balance > 0
),
month_customer_counts AS (
    SELECT
        "month",
        COUNT(DISTINCT "customer_id") AS positive_balance_customers
    FROM positive_balances
    GROUP BY "month"
),
max_min_months AS (
    SELECT
        (SELECT "month" FROM month_customer_counts ORDER BY positive_balance_customers DESC LIMIT 1) AS max_month,
        (SELECT "month" FROM month_customer_counts ORDER BY positive_balance_customers ASC LIMIT 1) AS min_month
),
average_balances AS (
    SELECT
        "month",
        AVG(cumulative_balance) AS average_balance
    FROM positive_balances
    WHERE "month" IN (
        SELECT max_month FROM max_min_months 
        UNION 
        SELECT min_month FROM max_min_months
    )
    GROUP BY "month"
),
final_result AS (
    SELECT
        ROUND(ABS(
            (SELECT average_balance FROM average_balances WHERE "month" = (SELECT max_month FROM max_min_months)) -
            (SELECT average_balance FROM average_balances WHERE "month" = (SELECT min_month FROM max_min_months))
        ), 4) AS difference_in_average_month_end_balance
)
SELECT difference_in_average_month_end_balance
FROM final_result;