WITH monthly_nets AS (
    SELECT
        "customer_id",
        DATE("txn_date", 'start of month') AS "month",
        SUM(
            CASE
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS "monthly_net"
    FROM
        "customer_transactions"
    GROUP BY
        "customer_id", "month"
),
monthly_closing_balances AS (
    SELECT
        "customer_id",
        "month",
        "monthly_net",
        SUM("monthly_net") OVER (
            PARTITION BY "customer_id"
            ORDER BY "month"
        ) AS "closing_balance"
    FROM
        monthly_nets
),
customer_growth AS (
    SELECT
        "customer_id",
        "month",
        "closing_balance",
        LAG("closing_balance") OVER (
            PARTITION BY "customer_id"
            ORDER BY "month"
        ) AS "prev_closing_balance"
    FROM
        monthly_closing_balances
),
most_recent_month AS (
    SELECT
        MAX("month") AS "latest_month"
    FROM
        monthly_closing_balances
)
SELECT
    ROUND(
        COUNT(*) * 100.0 / (
            SELECT
                COUNT(DISTINCT "customer_id")
            FROM
                "customer_transactions"
        ),
        4
    ) AS "percentage_of_customers"
FROM
    customer_growth
    CROSS JOIN most_recent_month
WHERE
    "month" = "latest_month"
    AND (
        ("prev_closing_balance" = 0 AND "closing_balance" * 100 > 5)
        OR (
            "prev_closing_balance" <> 0
            AND (
                ("closing_balance" - "prev_closing_balance") * 100.0
                / ABS("prev_closing_balance")
            ) > 5
        )
    );