WITH monthly_balances AS (
    /* month‑end balance (deposits − withdrawals) for every customer and month in 2020 */
    SELECT
        customer_id,
        strftime('%m', txn_date) AS month_2020,
        SUM(
            CASE
                WHEN LOWER(txn_type) = 'deposit'     THEN  txn_amount
                WHEN LOWER(txn_type) = 'withdrawal' THEN -txn_amount
                ELSE 0
            END
        ) AS month_end_balance
    FROM customer_transactions
    WHERE txn_date BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY customer_id,
             month_2020
),
month_stats AS (
    /* for each month: how many customers finished positive and what was the average balance */
    SELECT
        month_2020,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END)  AS positive_customer_cnt,
        AVG(month_end_balance)                                   AS avg_month_end_balance
    FROM monthly_balances
    GROUP BY month_2020
),
most_positive AS (
    /* month with the highest count of positive balances (earlier month kept if tie) */
    SELECT *
    FROM month_stats
    ORDER BY positive_customer_cnt DESC, month_2020
    LIMIT 1
),
least_positive AS (
    /* month with the lowest count of positive balances (earlier month kept if tie) */
    SELECT *
    FROM month_stats
    ORDER BY positive_customer_cnt ASC, month_2020
    LIMIT 1
)
SELECT
    most_positive.month_2020        AS highest_positive_month,
    most_positive.positive_customer_cnt AS highest_positive_count,
    ROUND(most_positive.avg_month_end_balance, 4) AS highest_month_avg_balance,
    least_positive.month_2020       AS lowest_positive_month,
    least_positive.positive_customer_cnt AS lowest_positive_count,
    ROUND(least_positive.avg_month_end_balance, 4) AS lowest_month_avg_balance,
    /* difference between the two averages */
    ROUND(most_positive.avg_month_end_balance - least_positive.avg_month_end_balance, 4) 
        AS difference_between_averages
FROM most_positive
CROSS JOIN least_positive;