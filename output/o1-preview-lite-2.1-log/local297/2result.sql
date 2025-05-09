WITH dates AS (
    SELECT
        date(MAX("txn_date"), 'start of month') AS current_month_start,
        date(date(MAX("txn_date"), 'start of month'), '-1 month') AS previous_month_start,
        date(date(date(MAX("txn_date"), 'start of month'), '-1 day')) AS previous_month_end,
        date(date(date(MAX("txn_date"), 'start of month'), '-1 month'), '-1 day') AS two_months_ago_end
    FROM "customer_transactions"
),
balances AS (
    SELECT
        ct."customer_id",
        SUM(CASE WHEN ct."txn_date" <= (SELECT previous_month_end FROM dates) THEN ct."txn_amount" ELSE 0 END) AS current_balance,
        SUM(CASE WHEN ct."txn_date" <= (SELECT two_months_ago_end FROM dates) THEN ct."txn_amount" ELSE 0 END) AS previous_balance
    FROM "customer_transactions" AS ct
    GROUP BY ct."customer_id"
),
growth_rates AS (
    SELECT
        "customer_id",
        current_balance,
        previous_balance,
        CASE
            WHEN previous_balance = 0 OR previous_balance IS NULL THEN current_balance * 100.0
            ELSE ((current_balance - previous_balance) * 100.0) / previous_balance
        END AS growth_rate
    FROM balances
)
SELECT
    ROUND((SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 4) AS Percentage_of_users_with_growth_rate_over_5
FROM growth_rates;