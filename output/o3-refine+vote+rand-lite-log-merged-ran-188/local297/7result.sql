WITH signed_txns AS (
    SELECT
        "customer_id",
        DATE("txn_date")                                         AS txn_date,
        DATE("txn_date", 'start of month')                       AS month_start,
        CASE
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
            ELSE 0
        END                                                      AS signed_amount
    FROM "customer_transactions"
),
monthly_net AS (
    -- net amount for each customer & month
    SELECT
        "customer_id",
        "month_start",
        SUM(signed_amount)                                       AS monthly_net
    FROM signed_txns
    GROUP BY "customer_id", "month_start"
),
closing_balances AS (
    -- cumulative running balance
    SELECT
        "customer_id",
        "month_start",
        SUM(monthly_net) OVER (
            PARTITION BY "customer_id"
            ORDER BY "month_start"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                        AS closing_balance
    FROM monthly_net
),
closing_with_prev AS (
    -- add previous month’s closing balance
    SELECT
        "customer_id",
        "month_start",
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY "customer_id"
            ORDER BY "month_start"
        )                                                        AS prev_closing_balance
    FROM closing_balances
),
most_recent AS (
    -- latest month for each customer + growth rate
    SELECT
        cwp."customer_id",
        cwp."month_start",
        cwp.closing_balance,
        COALESCE(cwp.prev_closing_balance, 0)                    AS prev_balance,
        CASE
            WHEN COALESCE(cwp.prev_closing_balance, 0) = 0
                 THEN cwp.closing_balance * 100.0
            ELSE (cwp.closing_balance - cwp.prev_closing_balance) * 100.0
                 / cwp.prev_closing_balance
        END                                                      AS growth_rate
    FROM closing_with_prev cwp
    INNER JOIN (
        SELECT
            "customer_id",
            MAX("month_start") AS latest_month
        FROM closing_with_prev
        GROUP BY "customer_id"
    ) lm
        ON cwp."customer_id" = lm."customer_id"
       AND cwp."month_start" = lm.latest_month
),
final_stats AS (
    SELECT
        COUNT(*)                                                AS total_customers,
        SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)        AS customers_gt_5
    FROM most_recent
)
SELECT
    ROUND(customers_gt_5 * 100.0 / total_customers, 4)          AS pct_customers_growth_gt_5
FROM final_stats;