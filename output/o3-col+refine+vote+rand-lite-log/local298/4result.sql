WITH customer_month_net AS (
    /* 1. Work out each customer’s net movement for every month            */
    SELECT
        customer_id,
        substr(txn_date,1,7)                          AS month_yyyy_mm,
        SUM(CASE
                WHEN txn_type = 'deposit'     THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END)                                     AS net_month_amount
    FROM customer_transactions
    GROUP BY customer_id, month_yyyy_mm
),
customer_running_balance AS (
    /* 2. Convert monthly nets into a running (cumulative) balance         */
    SELECT
        customer_id,
        month_yyyy_mm,
        SUM(net_month_amount) OVER (
            PARTITION BY customer_id
            ORDER BY month_yyyy_mm
        )                                            AS cumulative_balance
    FROM customer_month_net
),
month_totals AS (
    /* 3. Sum all customer balances to get the platform balance each month */
    SELECT
        month_yyyy_mm,
        SUM(cumulative_balance)                      AS total_balance
    FROM customer_running_balance
    GROUP BY month_yyyy_mm
),
prev_month_platform_balance AS (
    /* 4. Grab the PREVIOUS month’s total, flooring negatives to zero      */
    SELECT
        month_yyyy_mm                                 AS month,
        CASE
            WHEN LAG(total_balance)
                 OVER (ORDER BY month_yyyy_mm) < 0    THEN 0
            ELSE LAG(total_balance)
                 OVER (ORDER BY month_yyyy_mm)
        END                                           AS prev_month_total_balance
    FROM month_totals
)
SELECT
    month,
    prev_month_total_balance
FROM prev_month_platform_balance
/* 5. Exclude the very first baseline month (where previous balance is NULL) */
WHERE prev_month_total_balance IS NOT NULL
ORDER BY month;