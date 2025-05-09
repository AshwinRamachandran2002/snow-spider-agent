WITH monthly_net AS (
    /* 1.  Net amount (deposits – withdrawals) for the first day of each month */
    SELECT
        customer_id,
        DATE(txn_date, 'start of month')       AS period_start,
        SUM(CASE
                WHEN LOWER(txn_type) = 'deposit'      THEN  txn_amount      -- positive
                WHEN LOWER(txn_type) = 'withdrawal'   THEN -txn_amount      -- negative
                ELSE 0
            END)                               AS net_amount
    FROM   customer_transactions
    GROUP  BY customer_id,
              DATE(txn_date, 'start of month')
),
closing_balances AS (
    /* 2.  Running (cumulative) month‑end balance per customer */
    SELECT
        customer_id,
        period_start,
        net_amount,
        SUM(net_amount) OVER (
              PARTITION BY customer_id
              ORDER BY     period_start
        )                                          AS closing_balance
    FROM   monthly_net
),
lagged_balances AS (
    /* 3.  Add previous month’s closing balance and flag the latest month */
    SELECT
        customer_id,
        period_start,
        closing_balance,
        LAG(closing_balance) OVER (
              PARTITION BY customer_id
              ORDER BY     period_start
        )                                          AS prev_closing_balance,
        ROW_NUMBER()      OVER (
              PARTITION BY customer_id
              ORDER BY     period_start DESC
        )                                          AS rn_latest
    FROM   closing_balances
),
latest_growth AS (
    /* 4.  Keep only each customer’s most‑recent month and derive growth rate */
    SELECT
        customer_id,
        closing_balance,
        prev_closing_balance,
        CASE
            WHEN prev_closing_balance IS NULL
                 OR prev_closing_balance = 0
                 THEN closing_balance * 100.0
            ELSE (closing_balance - prev_closing_balance) * 100.0
                 / prev_closing_balance
        END                                         AS growth_rate
    FROM   lagged_balances
    WHERE  rn_latest = 1
)
/* 5.  Percentage of customers with >5 % growth in their most‑recent month */
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    , 4)                               AS pct_customers_growth_gt_5
FROM   latest_growth;