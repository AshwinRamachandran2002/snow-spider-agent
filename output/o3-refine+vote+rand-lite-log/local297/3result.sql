WITH signed_txn AS (
    /* 1. Turn every transaction into a signed amount (+ for deposits, – for withdrawals)
         and trim the date down to the first day of its month                       */
    SELECT
        "customer_id",
        date(substr("txn_date",1,7) || '-01')           AS month_start,
        CASE
            WHEN lower("txn_type") = 'deposit' THEN  "txn_amount"
            ELSE                                       - "txn_amount"
        END                                             AS signed_amount
    FROM "customer_transactions"
),
/* 2. Net amount for each customer‑month */
monthly_net AS (
    SELECT
        customer_id,
        month_start,
        SUM(signed_amount)                              AS net_amount
    FROM signed_txn
    GROUP BY customer_id, month_start
),
/* 3. Closing balance = cumulative sum of monthly nets */
monthly_balances AS (
    SELECT
        customer_id,
        month_start,
        net_amount,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        )                                               AS closing_balance
    FROM monthly_net
),
/* 4. For every customer, pick the most‑recent month and also grab the
       previous month’s closing balance (if any)                             */
latest_balance AS (
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        )                                               AS prev_balance,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY month_start DESC
        )                                               AS rn               -- rn = 1 → latest month
    FROM monthly_balances
),
/* 5. Growth rate for each customer’s most‑recent month  */
growth_calc AS (
    SELECT
        customer_id,
        CASE
            WHEN COALESCE(prev_balance,0) = 0
                 THEN closing_balance * 100.0
            ELSE (closing_balance - prev_balance) * 100.0 / prev_balance
        END                                             AS growth_rate
    FROM latest_balance
    WHERE rn = 1
)
/* 6. Percentage of customers whose latest month grew by more than 5 % */
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END)
        / COUNT(*),
        4
    ) AS percentage_above_5
FROM growth_calc;