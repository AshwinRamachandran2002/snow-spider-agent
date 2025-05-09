WITH 
months AS (
    SELECT DISTINCT SUBSTR("txn_date", 1, 7) AS "month"
    FROM "customer_transactions"
),
customers AS (
    SELECT DISTINCT "customer_id"
    FROM "customer_nodes"
),
customer_months AS (
    SELECT c."customer_id", m."month"
    FROM customers c
    CROSS JOIN months m
),
monthly_transactions AS (
    SELECT
        ct."customer_id",
        SUBSTR(ct."txn_date", 1, 7) AS "month",
        SUM(
            CASE
                WHEN ct."txn_type" = 'deposit' THEN ct."txn_amount"
                WHEN ct."txn_type" IN ('withdrawal', 'purchase') THEN -ct."txn_amount"
                ELSE 0
            END
        ) AS "monthly_change"
    FROM
        "customer_transactions" ct
    GROUP BY
        ct."customer_id",
        SUBSTR(ct."txn_date", 1, 7)
),
customer_monthly_balances AS (
    SELECT
        cm."customer_id",
        cm."month",
        COALESCE(mt."monthly_change", 0) AS "monthly_change"
    FROM
        customer_months cm
    LEFT JOIN
        monthly_transactions mt
    ON
        cm."customer_id" = mt."customer_id" AND
        cm."month" = mt."month"
),
ordered_balances AS (
    SELECT
        cmb.*,
        ROW_NUMBER() OVER (PARTITION BY cmb."customer_id" ORDER BY cmb."month") AS rn
    FROM
        customer_monthly_balances cmb
),
final_balances AS (
    SELECT
        ob."customer_id",
        ob."month",
        ROUND(ob."monthly_change", 4) AS "monthly_change",
        ROUND(
            SUM(ob."monthly_change") OVER (
                PARTITION BY ob."customer_id"
                ORDER BY ob.rn
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ), 4
        ) AS "closing_balance"
    FROM
        ordered_balances ob
)
SELECT
    "customer_id",
    "month",
    "closing_balance",
    "monthly_change",
    "closing_balance" AS "cumulative_balance"
FROM
    final_balances
ORDER BY
    "customer_id",
    "month";