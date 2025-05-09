SELECT
    "month" AS "Month",
    ROUND(SUM("max_daily_balance"), 4) AS "Total_Max_Daily_Balance"
FROM (
    SELECT
        "customer_id",
        "month",
        MAX("adjusted_balance") AS "max_daily_balance"
    FROM (
        SELECT
            "customer_id",
            "month",
            "txn_date",
            GREATEST(
                SUM("daily_net_amount") OVER (
                    PARTITION BY "customer_id"
                    ORDER BY "txn_date"
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ),
                0
            ) AS "adjusted_balance"
        FROM (
            SELECT
                "customer_id",
                TO_CHAR(TO_DATE("txn_date"), 'YYYY-MM') AS "month",
                TO_DATE("txn_date") AS "txn_date",
                SUM(
                    CASE 
                        WHEN "txn_type" = 'deposit' THEN "txn_amount"
                        WHEN "txn_type" IN ('withdrawal', 'purchase') THEN - "txn_amount"
                        ELSE 0
                    END
                ) AS "daily_net_amount"
            FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
            WHERE "txn_type" IS NOT NULL AND "txn_amount" IS NOT NULL
            GROUP BY "customer_id", "txn_date"
        ) AS daily_net_amounts
    ) AS cumulative_balance
    GROUP BY "customer_id", "month"
) AS max_daily_balances
GROUP BY "month"
ORDER BY "month";