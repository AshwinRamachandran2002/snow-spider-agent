WITH monthly_net AS (   -- net movement for each customer per month
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD'))     AS month_start,
        SUM(
            CASE 
                WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
                WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
                ELSE 0
            END
        )                                                       AS net_amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY 
        "customer_id",
        DATE_TRUNC('month', TO_DATE("txn_date",'YYYY-MM-DD'))
),

closing_balances AS (   -- running balance by month
    SELECT
        "customer_id",
        month_start,
        net_amt,
        SUM(net_amt) OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS closing_balance
    FROM monthly_net
),

latest_balances AS (    -- add previous-month balance & flag most-recent row
    SELECT
        "customer_id",
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start
        )                                   AS prev_balance,
        ROW_NUMBER() OVER (
            PARTITION BY "customer_id"
            ORDER BY month_start DESC
        )                                   AS rn
    FROM closing_balances
),

most_recent AS (        -- growth rate for most-recent month per customer
    SELECT
        "customer_id",
        closing_balance                       AS current_balance,
        COALESCE(prev_balance,0)              AS prev_balance,
        CASE
            WHEN COALESCE(prev_balance,0) = 0 
                 THEN current_balance * 100
            ELSE ((current_balance - prev_balance) / prev_balance) * 100
        END                                   AS growth_rate
    FROM latest_balances
    WHERE rn = 1
)

SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS "percentage_customers_growth_gt_5"
FROM most_recent;