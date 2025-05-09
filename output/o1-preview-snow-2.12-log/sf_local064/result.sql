WITH monthly_balances AS (
    SELECT
        "customer_id",
        SUBSTRING("txn_date", 1, 7) AS "txn_month",
        SUM(
            CASE
                WHEN LOWER("txn_type") = 'deposit' THEN "txn_amount"
                WHEN LOWER("txn_type") IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS "month_end_balance"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE "txn_date" LIKE '2020%'
    GROUP BY "customer_id", "txn_month"
),
positive_counts AS (
    SELECT
        "txn_month",
        COUNT(DISTINCT CASE WHEN "month_end_balance" > 0 THEN "customer_id" END) AS "positive_balance_customers"
    FROM monthly_balances
    GROUP BY "txn_month"
),
max_min_counts AS (
    SELECT
        MAX("positive_balance_customers") AS max_positive,
        MIN("positive_balance_customers") AS min_positive
    FROM positive_counts
),
selected_months AS (
    SELECT pc."txn_month"
    FROM positive_counts pc
    JOIN max_min_counts mm
    ON pc."positive_balance_customers" = mm.max_positive OR pc."positive_balance_customers" = mm.min_positive
),
average_balances AS (
    SELECT
        mb."txn_month",
        AVG(mb."month_end_balance") AS "average_balance"
    FROM monthly_balances mb
    WHERE mb."txn_month" IN (SELECT "txn_month" FROM selected_months)
    GROUP BY mb."txn_month"
),
balance_diff AS (
    SELECT
        ROUND(ABS(MAX("average_balance") - MIN("average_balance")), 4) AS "Difference_between_averages"
    FROM average_balances
)
SELECT "Difference_between_averages" FROM balance_diff;