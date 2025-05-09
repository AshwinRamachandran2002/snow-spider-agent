WITH months AS (
    SELECT DISTINCT strftime('%Y-%m', "txn_date") AS "Month"
    FROM "customer_transactions"
),
months_excl_first AS (
    SELECT "Month"
    FROM months
    WHERE "Month" > (SELECT MIN("Month") FROM months)
),
customer_balances AS (
    SELECT m."Month", c."customer_id", COALESCE(SUM(ct."txn_amount"), 0) AS "balance"
    FROM months_excl_first m
    CROSS JOIN (SELECT DISTINCT "customer_id" FROM "customer_transactions") c
    LEFT JOIN "customer_transactions" ct
    ON ct."customer_id" = c."customer_id"
    AND ct."txn_date" < date(m."Month" || '-01')
    GROUP BY m."Month", c."customer_id"
),
customer_balances_nonnegative AS (
    SELECT "Month", "customer_id", CASE WHEN "balance" < 0 THEN 0 ELSE "balance" END AS "adjusted_balance"
    FROM customer_balances
),
total_balance_per_month AS (
    SELECT "Month", SUM("adjusted_balance") AS "Total_Balance"
    FROM customer_balances_nonnegative
    GROUP BY "Month"
    ORDER BY "Month"
)
SELECT "Month", "Total_Balance"
FROM total_balance_per_month;