WITH customer_month_balance AS (
    /* 1.  Net (“month‑end”) balance for every customer in every month of 2020 */
    SELECT
        customer_id,
        strftime('%Y-%m', txn_date)            AS month_yyyymm,
        SUM(
              CASE 
                  WHEN lower(txn_type) = 'deposit'     THEN  txn_amount
                  WHEN lower(txn_type) = 'withdrawal'  THEN -txn_amount
                  ELSE 0
              END
        )                                      AS month_end_balance
    FROM customer_transactions
    WHERE strftime('%Y', txn_date) = '2020'
    GROUP BY customer_id,
             strftime('%Y-%m', txn_date)
),
month_stats AS (
    /* 2.  Per‑month statistics */
    SELECT
        month_yyyymm                           AS month,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END)  AS positive_customer_cnt,
        AVG(month_end_balance)                                 AS avg_month_end_balance
    FROM customer_month_balance
    GROUP BY month_yyyymm
),
highest_month AS (
    /* 3a.  Month with the MOST customers showing a positive balance */
    SELECT month,
           avg_month_end_balance
    FROM   month_stats
    WHERE  positive_customer_cnt = (SELECT MAX(positive_customer_cnt)
                                    FROM month_stats)
    ORDER BY month            --  tie‑breaker: earliest month
    LIMIT 1
),
lowest_month AS (
    /* 3b.  Month with the FEWEST customers showing a positive balance */
    SELECT month,
           avg_month_end_balance
    FROM   month_stats
    WHERE  positive_customer_cnt = (SELECT MIN(positive_customer_cnt)
                                    FROM month_stats)
    ORDER BY month            --  tie‑breaker: earliest month
    LIMIT 1
)
SELECT
       h.month  AS month_highest_positive_balances,
       h.avg_month_end_balance AS avg_balance_in_highest_month,
       l.month  AS month_lowest_positive_balances,
       l.avg_month_end_balance AS avg_balance_in_lowest_month,
       h.avg_month_end_balance - l.avg_month_end_balance
           AS difference_between_averages
FROM   highest_month h,
       lowest_month  l;