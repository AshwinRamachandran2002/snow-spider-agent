WITH daily_net_amounts AS (
    SELECT
        "customer_id",
        "txn_date",
        SUM(
            CASE
                WHEN "txn_type" = 'deposit' THEN "txn_amount"
                WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                ELSE 0
            END
        ) AS "daily_net_amount"
    FROM
        "customer_transactions"
    GROUP BY
        "customer_id", "txn_date"
),
ordered_daily_net_amounts AS (
    SELECT
        "customer_id",
        "txn_date",
        "daily_net_amount",
        ROW_NUMBER() OVER (
            PARTITION BY "customer_id"
            ORDER BY "txn_date"
        ) AS "rn"
    FROM
        daily_net_amounts
),
recursive_balances AS (
    SELECT
        "customer_id",
        "txn_date",
        "rn",
        MAX(0, "daily_net_amount") AS "cumulative_balance"
    FROM
        ordered_daily_net_amounts
    WHERE
        "rn" = 1
    UNION ALL
    SELECT
        od."customer_id",
        od."txn_date",
        od."rn",
        MAX(0, rb."cumulative_balance" + od."daily_net_amount") AS "cumulative_balance"
    FROM
        ordered_daily_net_amounts od
    JOIN
        recursive_balances rb ON
            od."customer_id" = rb."customer_id" AND
            od."rn" = rb."rn" + 1
)
SELECT
    "month",
    ROUND(SUM("max_daily_balance"), 4) AS "Total_Max_Daily_Balance"
FROM (
    SELECT
        "customer_id",
        strftime('%Y-%m', "txn_date") AS "month",
        MAX("cumulative_balance") AS "max_daily_balance"
        FROM
            recursive_balances
        GROUP BY
            "customer_id", "month"
    ) AS max_daily_balances
GROUP BY
    "month"
ORDER BY
    "month";