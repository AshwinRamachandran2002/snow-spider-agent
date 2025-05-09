WITH month_balances AS (
    /* 1.  Month‑end balance for every customer and every month in 2020 */
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)          AS month_yyyy_mm,     -- e.g. 2020-01
        SUM(
            CASE 
                WHEN lower(txn_type) = 'deposit'                     THEN  txn_amount
                WHEN lower(txn_type) IN ('withdrawal','withdraw')    THEN -txn_amount
                ELSE 0
            END
        ) AS month_end_balance
    FROM customer_transactions
    WHERE txn_date BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY customer_id, month_yyyy_mm
),
month_stats AS (
    /* 2.  How many customers finished the month positive?  What was the average balance? */
    SELECT
        month_yyyy_mm,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END) AS positive_customer_cnt,
        AVG(month_end_balance)                                AS avg_balance
    FROM month_balances
    GROUP BY month_yyyy_mm
),
best_month AS (
    /* 3a.  Month with the MOST customers in positive territory */
    SELECT 
        month_yyyy_mm       AS highest_month,
        positive_customer_cnt   AS highest_positive_customers,
        avg_balance             AS highest_avg_balance
    FROM month_stats
    ORDER BY positive_customer_cnt DESC, month_yyyy_mm        -- earliest month if tie
    LIMIT 1
),
worst_month AS (
    /* 3b.  Month with the FEWEST customers in positive territory */
    SELECT 
        month_yyyy_mm       AS lowest_month,
        positive_customer_cnt   AS lowest_positive_customers,
        avg_balance             AS lowest_avg_balance
    FROM month_stats
    ORDER BY positive_customer_cnt ASC, month_yyyy_mm          -- earliest month if tie
    LIMIT 1
)
SELECT
    b.highest_month,
    b.highest_positive_customers,
    ROUND(b.highest_avg_balance, 4)            AS highest_avg_balance,
    w.lowest_month,
    w.lowest_positive_customers,
    ROUND(w.lowest_avg_balance, 4)             AS lowest_avg_balance,
    ROUND(b.highest_avg_balance - w.lowest_avg_balance, 4) 
                                               AS avg_balance_difference
FROM best_month  b
CROSS JOIN worst_month w;