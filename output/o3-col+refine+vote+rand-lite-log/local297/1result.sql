WITH monthly AS (
    SELECT 
        "customer_id",
        strftime('%Y-%m-01', "txn_date") AS "month_start",
        SUM(
            CASE 
                WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
            END
        ) AS "monthly_net"
    FROM "customer_transactions"
    GROUP BY "customer_id", "month_start"
),
closing AS (
    SELECT
        "customer_id",
        "month_start",
        SUM("monthly_net") OVER (
            PARTITION BY "customer_id"
            ORDER BY "month_start"
        ) AS "closing_balance"
    FROM monthly
),
latest AS (
    SELECT
        c."customer_id",
        c."month_start",
        c."closing_balance",
        LAG(c."closing_balance") OVER (
            PARTITION BY c."customer_id"
            ORDER BY c."month_start"
        ) AS "prev_balance"
    FROM closing c
),
growth AS (
    SELECT
        "customer_id",
        CASE
            WHEN "prev_balance" IS NULL OR "prev_balance" = 0
                 THEN "closing_balance" * 100.0
            ELSE (("closing_balance" - "prev_balance") * 100.0) 
                 / ABS("prev_balance")
        END AS "growth_pct"
    FROM latest
    WHERE "month_start" = (
        SELECT MAX("month_start")
        FROM closing AS x
        WHERE x."customer_id" = latest."customer_id"
    )
)
SELECT 
    ROUND(
        100.0 * SUM(CASE WHEN "growth_pct" > 5 THEN 1 ELSE 0 END) 
        / COUNT(*), 
        2
    ) AS "percent_growth_gt_5"
FROM growth;