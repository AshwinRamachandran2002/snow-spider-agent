WITH adjusted_transactions AS (
    SELECT
        "customer_id",
        TO_DATE("txn_date") AS "txn_date",
        "txn_type",
        CASE
            WHEN "txn_type" = 'deposit' THEN "txn_amount"
            WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
            ELSE 0
        END AS "adjusted_txn_amount"
    FROM
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
adjusted_transactions_by_date AS (
    SELECT
        "customer_id",
        "txn_date",
        SUM("adjusted_txn_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_balance"
    FROM adjusted_transactions
),
balances_on_first_of_month AS (
    SELECT
        "customer_id",
        "txn_date" AS "balance_date",
        "cumulative_balance" AS "balance"
    FROM adjusted_transactions_by_date
    WHERE DAY("txn_date") = 1
),
current_and_previous_months AS (
    SELECT DISTINCT
        "balance_date"
    FROM balances_on_first_of_month
    ORDER BY "balance_date" DESC NULLS LAST
    LIMIT 2
),
balances AS (
    SELECT
        b."customer_id",
        b."balance_date",
        b."balance"
    FROM balances_on_first_of_month b
    JOIN current_and_previous_months cpm
        ON b."balance_date" = cpm."balance_date"
),
balance_pivot AS (
    SELECT
        "customer_id",
        MAX(CASE WHEN "balance_date" = (SELECT MAX("balance_date") FROM current_and_previous_months) THEN "balance" END) AS "current_balance",
        MAX(CASE WHEN "balance_date" = (SELECT MIN("balance_date") FROM current_and_previous_months) THEN "balance" END) AS "previous_balance"
    FROM balances
    GROUP BY "customer_id"
)
SELECT
    ROUND(
        (COUNT(CASE
            WHEN
                CASE
                    WHEN "previous_balance" = 0 OR "previous_balance" IS NULL THEN "current_balance" * 100
                    ELSE ("current_balance" - "previous_balance") / ABS("previous_balance")
                END > 0.05
            THEN 1 END
        ) * 100.0) / NULLIF(COUNT(*), 0), 4) AS "Percentage_of_users_with_growth_rate_over_5_percent"
FROM balance_pivot;