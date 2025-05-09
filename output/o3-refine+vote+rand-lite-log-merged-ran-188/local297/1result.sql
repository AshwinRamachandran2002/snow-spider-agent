WITH monthly_net AS (            -- 1. net deposits/withdrawals per first day of month
    SELECT
        "customer_id",
        date(substr("txn_date",1,7) || '-01')      AS "month_start",
        SUM(CASE
                WHEN lower("txn_type") = 'deposit'    THEN  "txn_amount"
                WHEN lower("txn_type") = 'withdrawal' THEN - "txn_amount"
                ELSE 0
            END)                                   AS "net_amount"
    FROM "customer_transactions"
    GROUP BY "customer_id", date(substr("txn_date",1,7) || '-01')
),
closing_balances AS (           -- 2. running (cumulative) balance
    SELECT
        "customer_id",
        "month_start",
        "net_amount",
        SUM("net_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY       "month_start"
        )                                         AS "closing_balance"
    FROM monthly_net
),
growth_calc AS (                -- 3. bring in previous‑month balance
    SELECT
        "customer_id",
        "month_start",
        "closing_balance",
        LAG("closing_balance") OVER (
            PARTITION BY "customer_id"
            ORDER BY       "month_start"
        )                                         AS "prev_balance"
    FROM closing_balances
),
latest_growth AS (              -- 4. latest month per customer + growth rate
    SELECT
        "customer_id",
        "closing_balance",
        "prev_balance",
        CASE
            WHEN "prev_balance" IS NULL OR "prev_balance" = 0
                 THEN "closing_balance" * 100.0
            ELSE ("closing_balance" - "prev_balance") * 100.0 / "prev_balance"
        END                                    AS "growth_rate",
        ROW_NUMBER() OVER (
            PARTITION BY "customer_id"
            ORDER BY       "month_start" DESC
        )                                       AS rn
    FROM growth_calc
)
-- 5. percentage of customers whose most‑recent month’s growth > 5 %
SELECT
    ROUND(
        SUM(CASE WHEN "growth_rate" > 5 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        4
    ) AS "percentage_customers_growth_gt_5"
FROM latest_growth
WHERE rn = 1;