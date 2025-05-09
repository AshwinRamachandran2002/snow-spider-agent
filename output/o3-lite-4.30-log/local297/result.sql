WITH filtered_txn AS (
    SELECT
        "customer_id",
        DATE(substr("txn_date",1,7) || '-01')               AS "month_start",
        CASE
            WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
            WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
        END                                                 AS "signed_amt"
    FROM "customer_transactions"
    WHERE "txn_type" IN ('deposit','withdrawal')
),
monthly_net AS (
    SELECT
        "customer_id",
        "month_start",
        SUM("signed_amt")                                   AS "net_amt"
    FROM filtered_txn
    GROUP BY "customer_id","month_start"
),
closing_bal AS (
    SELECT
        "customer_id",
        "month_start",
        SUM("net_amt") OVER (PARTITION BY "customer_id"
                             ORDER BY      "month_start")   AS "closing_balance"
    FROM monthly_net
),
growth AS (
    SELECT
        "customer_id",
        "month_start",
        "closing_balance",
        LAG("closing_balance") OVER (PARTITION BY "customer_id"
                                     ORDER BY      "month_start") AS "prev_balance"
    FROM closing_bal
),
growth_rate AS (
    SELECT
        "customer_id",
        100.0 *
        CASE
            WHEN "prev_balance" IS NULL OR "prev_balance" = 0
                 THEN "closing_balance"
            ELSE ("closing_balance" - "prev_balance") / "prev_balance"
        END                                                AS "growth_rate_pct",
        ROW_NUMBER() OVER (PARTITION BY "customer_id"
                           ORDER BY      "month_start" DESC) AS "rn"
    FROM growth
),
flags AS (
    SELECT
        "customer_id",
        CASE WHEN "growth_rate_pct" > 5 THEN 1 ELSE 0 END  AS "gt5"
    FROM growth_rate
    WHERE "rn" = 1
)
SELECT
    ROUND(100.0 * SUM("gt5") / COUNT(*), 2) AS percentage_of_customers_with_growth_rate_gt_5
FROM flags;