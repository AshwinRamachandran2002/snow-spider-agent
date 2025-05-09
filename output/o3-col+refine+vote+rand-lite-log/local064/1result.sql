WITH month_balances AS (
    /* 1.  Month-end balance per customer */
    SELECT
        customer_id,
        substr(txn_date,1,7)                 AS month,          -- YYYY-MM
        SUM(
            CASE
                WHEN txn_type = 'deposit'    THEN  txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END
        )                                    AS month_end_balance
    FROM   customer_transactions
    WHERE  substr(txn_date,1,4) = '2020'
    GROUP  BY customer_id, month
),
/* 2.  How many customers finished each month with a POSITIVE balance */
pos_counts AS (
    SELECT  month,
            COUNT(*) AS positive_cust_cnt
    FROM    month_balances
    WHERE   month_end_balance > 0
    GROUP   BY month
),
/* 3.  Identify the BEST (most positives) and WORST (fewest positives) months */
hi_month AS (
    SELECT month
    FROM   pos_counts
    ORDER  BY positive_cust_cnt DESC, month
    LIMIT 1
),
lo_month AS (
    SELECT month
    FROM   pos_counts
    ORDER  BY positive_cust_cnt ASC, month
    LIMIT 1
),
/* 4.  Average balances for those two months */
avg_hi AS (
    SELECT AVG(month_end_balance) AS avg_bal_hi
    FROM   month_balances
    WHERE  month = (SELECT month FROM hi_month)
),
avg_lo AS (
    SELECT AVG(month_end_balance) AS avg_bal_lo
    FROM   month_balances
    WHERE  month = (SELECT month FROM lo_month)
)
/* 5.  Final answer */
SELECT
        (SELECT month FROM hi_month)                        AS highest_positive_month,
        (SELECT month FROM lo_month)                        AS lowest_positive_month,
        ROUND((SELECT avg_bal_hi FROM avg_hi),4)            AS avg_balance_high_month,
        ROUND((SELECT avg_bal_lo FROM avg_lo),4)            AS avg_balance_low_month,
        ROUND(
              (SELECT avg_bal_hi FROM avg_hi)
            - (SELECT avg_bal_lo FROM avg_lo)
        ,4)                                                 AS difference_between_averages;