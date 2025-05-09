WITH month_balances AS (
    /* 1.  Month-end balance per customer for every month in 2020 */
    SELECT  customer_id,
            substr(txn_date,1,7)                       AS month,      -- YYYY-MM
            SUM(
                CASE
                    WHEN txn_type = 'deposit'    THEN  txn_amount         -- add deposits
                    WHEN txn_type = 'withdrawal' THEN -txn_amount         -- subtract withdrawals
                    ELSE 0                                                -- ignore purchases or others
                END
            ) AS month_end_balance
    FROM    customer_transactions
    WHERE   substr(txn_date,1,4) = '2020'
    GROUP BY customer_id,
             substr(txn_date,1,7)
),
month_stats AS (
    /* 2.  For each month: how many customers are positive & avg balance of all customers */
    SELECT  month,
            SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END) AS pos_customer_cnt,
            AVG(month_end_balance)                                 AS avg_balance
    FROM    month_balances
    GROUP BY month
),
top_month AS (
    /* 3.  Month with the HIGHEST count of customers in positive territory */
    SELECT  month,
            avg_balance
    FROM    month_stats
    ORDER BY pos_customer_cnt DESC, month            -- tie-break on month just for determinism
    LIMIT 1
),
bottom_month AS (
    /* 4.  Month with the LOWEST count of customers in positive territory */
    SELECT  month,
            avg_balance
    FROM    month_stats
    ORDER BY pos_customer_cnt ASC, month
    LIMIT 1
)
SELECT  top_month.month              AS highest_positive_month,
        bottom_month.month           AS lowest_positive_month,
        top_month.avg_balance        AS highest_month_avg_balance,
        bottom_month.avg_balance     AS lowest_month_avg_balance,
        (top_month.avg_balance - bottom_month.avg_balance) 
                                      AS avg_balance_difference
FROM    top_month, bottom_month;