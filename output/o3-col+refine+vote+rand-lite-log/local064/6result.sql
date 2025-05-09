WITH balances AS (
    /* Month-end balance (deposits – withdrawals) for every customer in 2020 */
    SELECT  customer_id,
            substr(txn_date,1,7) AS yyyymm,
            SUM(
                CASE txn_type
                     WHEN 'deposit'    THEN  txn_amount
                     WHEN 'withdrawal' THEN -txn_amount
                     ELSE 0
                END
            )                   AS month_end_balance
    FROM    customer_transactions
    WHERE   substr(txn_date,1,4) = '2020'
    GROUP BY customer_id,
             substr(txn_date,1,7)
),
pos_counts AS (
    /* How many customers finished each month with a positive balance */
    SELECT  yyyymm,
            COUNT(*) AS positive_customer_cnt
    FROM    balances
    WHERE   month_end_balance > 0
    GROUP BY yyyymm
),
high_month AS (               /* month with the MOST positive balances */
    SELECT yyyymm
    FROM   pos_counts
    ORDER  BY positive_customer_cnt DESC, yyyymm   -- tie-break: earliest month
    LIMIT  1
),
low_month AS (                /* month with the LEAST positive balances */
    SELECT yyyymm
    FROM   pos_counts
    ORDER  BY positive_customer_cnt ASC, yyyymm   -- tie-break: earliest month
    LIMIT  1
),
avg_high AS (
    SELECT  AVG(month_end_balance) AS high_avg
    FROM    balances
    WHERE   yyyymm = (SELECT yyyymm FROM high_month)
),
avg_low AS (
    SELECT  AVG(month_end_balance) AS low_avg
    FROM    balances
    WHERE   yyyymm = (SELECT yyyymm FROM low_month)
)
SELECT  avg_high.high_avg                 AS highest_month_avg,
        avg_low.low_avg                   AS lowest_month_avg,
        avg_high.high_avg - avg_low.low_avg
                                         AS avg_difference
FROM    avg_high, avg_low;