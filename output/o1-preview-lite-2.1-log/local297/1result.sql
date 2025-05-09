WITH
previous_balances AS (
    SELECT
        "customer_id",
        SUM(CASE WHEN "txn_type" = 'deposit' THEN "txn_amount" ELSE - "txn_amount" END) AS "previous_balance"
    FROM
        "customer_transactions"
    WHERE
        DATE("txn_date") < '2020-04-01'
    GROUP BY
        "customer_id"
),
current_balances AS (
    SELECT
        "customer_id",
        SUM(CASE WHEN "txn_type" = 'deposit' THEN "txn_amount" ELSE - "txn_amount" END) AS "current_balance"
    FROM
        "customer_transactions"
    WHERE
        DATE("txn_date") < '2020-05-01'
    GROUP BY
        "customer_id"
),
balances AS (
    SELECT
        c."customer_id",
        c."current_balance",
        COALESCE(p."previous_balance", 0) AS "previous_balance"
    FROM
        current_balances c
    LEFT JOIN
        previous_balances p
    ON
        c."customer_id" = p."customer_id"
),
growth_rates AS (
    SELECT
        "customer_id",
        "current_balance",
        "previous_balance",
        CASE
            WHEN "previous_balance" = 0 THEN ("current_balance" * 100.0)
            ELSE (("current_balance" - "previous_balance") * 1.0 / ABS("previous_balance"))
        END AS "growth_rate"
    FROM
        balances
)
SELECT
    ROUND((COUNT(CASE WHEN "growth_rate" > 0.05 THEN 1 END) * 1.0 / COUNT(*)) * 100, 4) AS "Percentage_of_users_with_growth_rate_over_5"
FROM
    growth_rates;