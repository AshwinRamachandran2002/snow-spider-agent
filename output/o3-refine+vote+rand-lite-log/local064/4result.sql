WITH monthly_balances AS (
    /* 1.  Month‑end balance for every customer & month in 2020 */
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)    AS month_ym,
        SUM(
            CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount       -- add deposits
                WHEN txn_type = 'withdrawal' THEN -txn_amount       -- subtract withdrawals
                ELSE 0
            END
        )                                AS month_end_balance
    FROM customer_transactions
    WHERE strftime('%Y', txn_date) = '2020'
    GROUP BY customer_id, month_ym
),
positive_counts AS (
    /* 2.  How many customers ended each month with a positive balance? */
    SELECT
        month_ym,
        COUNT(CASE WHEN month_end_balance > 0 THEN 1 END) AS positive_customer_cnt
    FROM monthly_balances
    GROUP BY month_ym
),
extremes AS (
    /* 3.  Identify the months with the highest and lowest positive‑balance counts */
    SELECT
        /* month with most customers having positive balance */
        (SELECT month_ym
         FROM   positive_counts
         ORDER  BY positive_customer_cnt DESC, month_ym
         LIMIT  1) AS max_month,
        (SELECT positive_customer_cnt
         FROM   positive_counts
         ORDER  BY positive_customer_cnt DESC, month_ym
         LIMIT  1) AS max_month_cnt,
        /* month with fewest customers having positive balance */
        (SELECT month_ym
         FROM   positive_counts
         ORDER  BY positive_customer_cnt ASC, month_ym
         LIMIT  1) AS min_month,
        (SELECT positive_customer_cnt
         FROM   positive_counts
         ORDER  BY positive_customer_cnt ASC, month_ym
         LIMIT  1) AS min_month_cnt
),
average_balances AS (
    /* 4.  Average month‑end balance for every month */
    SELECT
        month_ym,
        AVG(month_end_balance) AS avg_month_end_balance
    FROM monthly_balances
    GROUP BY month_ym
)
SELECT
    e.max_month                      AS highest_customer_count_month,
    e.max_month_cnt                  AS highest_positive_customer_cnt,
    ab_max.avg_month_end_balance     AS highest_month_avg_balance,
    e.min_month                      AS lowest_customer_count_month,
    e.min_month_cnt                  AS lowest_positive_customer_cnt,
    ab_min.avg_month_end_balance     AS lowest_month_avg_balance,
    ABS(ab_max.avg_month_end_balance
        - ab_min.avg_month_end_balance) AS difference_between_averages
FROM extremes e
JOIN average_balances ab_max ON ab_max.month_ym = e.max_month
JOIN average_balances ab_min ON ab_min.month_ym = e.min_month;