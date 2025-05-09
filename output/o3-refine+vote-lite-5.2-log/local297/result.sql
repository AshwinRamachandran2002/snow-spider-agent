WITH monthly_net AS (                -- 1. net deposits‑withdrawals per month
    SELECT
        customer_id,
        date(txn_date,'start of month')      AS month_start,
        SUM(
            CASE 
                 WHEN txn_type='deposit'     THEN  txn_amount
                 WHEN txn_type='withdrawal'  THEN -txn_amount
                 ELSE 0
            END
        )                                    AS monthly_net
    FROM customer_transactions
    GROUP BY customer_id, month_start
),
running_balance AS (                  -- 2. cumulative closing balance
    SELECT
        customer_id,
        month_start,
        SUM(monthly_net) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                              AS closing_balance
    FROM monthly_net
),
growth_calc AS (                      -- 3. month‑on‑month growth rate
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        )                              AS prev_balance
    FROM running_balance
),
latest_growth AS (                    -- 4. keep only each customer’s latest month
    SELECT
        customer_id,
        closing_balance,
        COALESCE(prev_balance,0)       AS prev_balance,
        CASE
            WHEN COALESCE(prev_balance,0)=0
                 THEN closing_balance * 100.0       -- definition when previous = 0
            ELSE (closing_balance-prev_balance) * 100.0 / prev_balance
        END                            AS growth_rate,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month_start DESC
        )                              AS rn
    FROM growth_calc
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
        / COUNT(*)
    ,4)                                AS percentage_of_customers_above_5pct
FROM latest_growth
WHERE rn = 1;                          -- only the most recent month per customer