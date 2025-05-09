WITH monthly_net AS (
    /* 1.  Net movement (deposit – withdrawal) for the whole customer base by month */
    SELECT
        strftime('%Y-%m', "txn_date")     AS month,
        SUM(
            CASE
                WHEN "txn_type" = 'deposit'                THEN  "txn_amount"
                WHEN "txn_type" IN ('withdraw', 'withdrawal') THEN - "txn_amount"
                ELSE 0
            END
        )                                  AS net_total
    FROM "customer_transactions"
    GROUP BY month
),
cumulative_bal AS (
    /* 2.  Running (cumulative) balance at the end of every month */
    SELECT
        month,
        SUM(net_total) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_balance
    FROM monthly_net
),
prev_month_bal AS (
    /* 3.  Balance as of the *start* of each month (i.e. end of previous month) */
    SELECT
        month,
        LAG(cumulative_balance) OVER (ORDER BY month) AS prev_balance
    FROM cumulative_bal
)
SELECT
    /* Represent the month as the 1st day of that month */
    date(month || '-01')                   AS month_start,
    CASE
        WHEN prev_balance < 0 THEN 0
        ELSE prev_balance
    END                                    AS previous_month_total_balance
FROM prev_month_bal
WHERE prev_balance IS NOT NULL          -- drop the first (baseline) month
ORDER BY month_start;