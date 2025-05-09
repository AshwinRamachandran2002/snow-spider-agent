WITH monthly_net AS (
    /* 1.  Net amount per customer per month (deposits = +, withdrawals = -) */
    SELECT
        customer_id,
        DATE(SUBSTR(txn_date,1,7) || '-01')      AS month_start,         -- first day of month
        SUM(CASE WHEN LOWER(txn_type) = 'deposit'
                 THEN txn_amount
                 ELSE -txn_amount END)            AS net_amount
    FROM customer_transactions
    GROUP BY customer_id,
             month_start
),
monthly_closing AS (
    /* 2.  Closing balance per month (cumulative sum of monthly nets) */
    SELECT
        customer_id,
        month_start,
        net_amount,
        SUM(net_amount) OVER (PARTITION BY customer_id
                              ORDER BY month_start) AS closing_balance
    FROM monthly_net
),
growth_prep AS (
    /* 3.  Previous month’s balance for growth‑rate calc */
    SELECT
        customer_id,
        month_start,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id
                                   ORDER BY month_start) AS prev_balance
    FROM monthly_closing
),
latest_month AS (
    /* 4.  Keep only the most‑recent month for each customer */
    SELECT *
    FROM (
        SELECT
            customer_id,
            month_start,
            closing_balance,
            prev_balance,
            ROW_NUMBER() OVER (PARTITION BY customer_id
                               ORDER BY month_start DESC) AS rn
        FROM growth_prep
    )
    WHERE rn = 1
),
growth_rate AS (
    /* 5.  Growth rate for the most‑recent month */
    SELECT
        customer_id,
        CASE
            WHEN prev_balance IS NULL           THEN NULL                       -- no prior month
            WHEN prev_balance = 0              THEN closing_balance * 100.0     -- per spec
            ELSE (closing_balance - prev_balance) * 100.0 / prev_balance
        END AS growth_pct
    FROM latest_month
),
summary AS (
    /* 6.  Totals for percentage calculation */
    SELECT
        COUNT(DISTINCT customer_id)                                AS total_customers,
        SUM(CASE WHEN growth_pct > 5.0 THEN 1 ELSE 0 END)          AS above_5_customers
    FROM growth_rate
)
SELECT
    ROUND(above_5_customers * 100.0 / total_customers, 4) AS percentage_customers_above_5_growth
FROM summary;