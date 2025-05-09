WITH monthly_net AS (
    /* 1.  Net deposits (+) and withdrawals (−) per customer per month */
    SELECT
        customer_id,
        DATE(txn_date,'start of month')      AS month_start,
        SUM(
            CASE 
                WHEN LOWER(txn_type) = 'deposit'      THEN  txn_amount
                /* treat anything that is not a deposit as a withdrawal */
                ELSE                                     -txn_amount
            END
        )                                    AS net_amount
    FROM customer_transactions
    GROUP BY customer_id, month_start
),
closing_balances AS (
    /* 2.  Running (closing) balance for every month */
    SELECT
        customer_id,
        month_start,
        net_amount,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY     month_start
        )                                   AS closing_balance
    FROM monthly_net
),
closing_with_prev AS (
    /* 3.  Add the preceding month’s closing balance */
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY     month_start
        )                                   AS prev_balance
    FROM closing_balances
),
latest_month AS (
    /* 4.  Keep only the most‑recent month for every customer */
    SELECT
        customer_id,
        month_start,
        closing_balance,
        COALESCE(prev_balance,0)            AS prev_balance,
        ROW_NUMBER()  OVER (
            PARTITION BY customer_id 
            ORDER BY     month_start DESC
        )                                   AS rn
    FROM closing_with_prev
),
growth_calc AS (
    /* 5.  Compute growth rate for that most‑recent month */
    SELECT
        customer_id,
        CASE 
            WHEN prev_balance = 0
                 THEN closing_balance * 100.0                        -- previous balance is zero
            ELSE (closing_balance - prev_balance) * 100.0 / prev_balance
        END                     AS growth_rate
    FROM latest_month
    WHERE rn = 1
)
/* 6.  Percentage of customers whose growth rate > 5 % */
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    , 4) AS percentage_customers_growth_gt_5
FROM growth_calc;